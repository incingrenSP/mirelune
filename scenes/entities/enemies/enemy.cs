using Godot;

public partial class Enemy : Entity
{
    [Export]
    private AnimatedSprite3D _sprite;
    [Export]
    private Player player { get; set; }
    [Export]
    private Area3D _patrolBoundary;

    [Export]
    private bool _routineEnabled = true;
    [Export]
    private float _waitTime = 1.0f;
    [Export]
    private bool _inCombat = false;
    [Export]
    private float _attackDuration = 0.5f;
    [Export]
    float _attackCooldown = 1.0f;

    private const float WalkSpeed = 4.0f;
    private const float RunSpeed = 7.0f;
    private const float Gravity = 18.0f;
    private const float WaypointReachedDistance = 0.2f;
    private const float AttackRange = 1.5f;

    private float _attackTimer = 0.0f;
    private float _attackCooldownTimer = 0.0f;
    private bool _attackLanded = false;

    private float _patrolRadius;
    private float _detectionRadius;
    private float _investigationRadius;
    private float _engageRadius;

    public int EnemyLevel { get; set; } = 1;
    public float MaxSp { get; set; } = 100.0f;
    public float Sp { get; set; } = 0.0f;
    public int MaxXp { get; set; } = 100;
    public int Xp { get; set; } = 0;

    public float SpRegenRate { get; set; } = 8.0f;
    // this is percentage rate
    // 5% /s not 5 units/s
    public float HpRegenRate { get; set; } = 5.0f;

    private Vector3 _moveTarget;
    private Vector3 _spawnPosition;

    private bool _facingRight = true;
    private bool _returningHome = false;
    private bool _isHovered = false;

    public enum EnemyStatesPassive
    {
        Patrol,
        SlowPatrol,
        Watch,
        Investigate,
        Disengage
    }

    public enum EnemyStatesActive
    {
        Attack,
        Chase,
        Run,
        Heal
    }

    private EnemyStatesPassive _passiveState = EnemyStatesPassive.Patrol;
    private EnemyStatesActive _activeState = EnemyStatesActive.Chase;

    private float _watchTimer = 0.0f;
    private float _watchDuration = 0.0f;

    private MeshInstance3D _hpBar;
    private MeshInstance3D _spBar;
    private Node3D _resourceBars;

    public override void _Ready()
    {
        base._Ready();

        _hpBar = GetNode<MeshInstance3D>("WorldUI/ResourceBars/HPBarFG");
        _spBar = GetNode<MeshInstance3D>("WorldUI/ResourceBars/SPBarFG");

        _resourceBars = GetNode<Node3D>("WorldUI/ResourceBars");

        _hpBarMaterial = _hpBar.MaterialOverride as ShaderMaterial;
        _spBarMaterial = _spBar.MaterialOverride as ShaderMaterial;

        CollisionShape3D collisionShape = _patrolBoundary.GetNode("Range");
        Shape3D shape = _collisionShape.Shape;

        if (shape is SphereShape3D)
        {
            _patrolRadius = shape.Radius;
        }
        else
        {
            GD.PushError("PatrolZone/Range's CollisionShape3D isn't a SphereShape3D.");
        }

        _detectionRadius = 0.8 * _patrolRadius;
        _investigationRadius = 0.6 * _patrolRadius;
        _engageRadius = 0.4 * _patrolRadius;

        _spawnPosition = GlobalPosition;

        if (!_inCombat)
        {
            PickNewPatrolPoint();
        }

    }

    public override void _PhysicsProcess(double delta)
    {
        if (!IsOnFloor())
        {
            Velocity = new Vector3(
                Velocity.X,
                Velocity.Y - Gravity * (float)delta,
                Velocity.Z
            );
        }
        else
        {
            Velocity.Y = 0.0f;
        }

        if (_inCombat)
        {
            ProcessActiveState(delta);
        }
        else
        {
            ProcessPassiveState(delta);
        }

        MoveAndSlide();
    }

    public override void _Process(double delta)
    {
        if (_inCombat)
        {
            if (Sp < MaxSp)
            {
                Sp = min(Sp + SpRegenRate * (float)delta, MaxSp);
            }
        }
        else if (!_inCombat)
        {
            if (Hp < MaxHp)
            {
                HpRegenRate = min(HpRegenRate + HpRegenRate * MaxHp * (float)delta, MaxHp);
            }
        }

        ResourceBarTransition();
    }

    private void ProcessPassiveState(double delta)
    {
        float distanceToPlayer = HorizontalDistanceToPlayer();
        float distanceToSpawn = HorizontalDistanceToSpawn();

        if (distanceToPlayer <= _engageRadius)
        {
            EnterCombat();
            return;
        }

        if (distanceToPlayer > _patrolRadius)
        {
            // Continue passive behavior
            pass;
        }

        switch (_passiveState)
        {
            case EnemyStatesPassive.Patrol:
                if (_routineEnabled && WalkRoutine(WalkSpeed))
                {
                    EnterWatch();
                }
                if (distanceToPlayer < _detectionRadius)
                {
                    EnterWatch();
                }
                break;

            case EnemyStatesPassive.SlowPatrol:
                if (_routineEnabled)
                {
                    WalkRoutine(WalkSpeed);
                }
                if (distanceToPlayer >= _detectionRadius)
                {
                    EnterWatch();
                }
                else if (distanceToPlayer < _investigationRadius)
                {
                    EnterWatch();
                }
                break;
            
            case EnemyStatesPassive.Watch:
                Velocity = new Vector3(0, 0, 0);
                UpdateSprite(Vector3.Zero);

                _watchTimer += (float)delta;
                if (_watchTimer >= _watchDuration)
                {
                    ResolveWatch(distanceToPlayer, distanceToSpawn);
                }
                break;

            case EnemyStatesPassive.Investigate:
                ChasePlayer(distanceToPlayer, WalkSpeed);

                if (distanceToPlayer < _engageRadius)
                {
                    EnterCombat();
                }
                else if (distanceToPlayer > _detectionRadius && distanceToSpawn > _patrolRadius)
                {
                    EnterWatch();
                }
                break;
            
            case EnemyStatesPassive.Disengage:
                _moveTarget = _spawnPosition;
                Vector3 dir = GlobalPosition.DirectionTo(_spawnPosition);
                dir.Y = 0.0f;

                Velocity = new Vector3(
                    dir.X * WalkSpeed,
                    0,
                    dir.Z * WalkSpeed
                );

                UpdateSprite(dir);

                if (distanceToPlayer <= WaypointReachedDistance)
                {
                    Vector3 position = GlobalPosition;
                    position.X = _spawnPosition.X;
                    position.Z = _spawnPosition.Z;

                    GlobalPosition = position;

                    Vector3 velocity = velocity;
                    velocity.X = 0.0f;
                    velocity.Z = 0.0f;

                    velocity = velocity;

                    PickNewPatrolPoint();
                    _passiveState = EnemyStatesPassive.Patrol;
                }
        }
    }

    private void ProcessActiveState(double delta)
    {
        Vector3 distanceToPlayer = GlobalPosition.DistanceTo(player.GlobalPosition);
        Vector3 distanceToSpawn = GlobalPosition.DistanceTo(_spawnPosition);

        switch (_activeState)
        {
            case EnemyStatesActive.Chase:
                ChasePlayer(distanceToPlayer, RunSpeed);

                if (distanceToPlayer < AttackRange && _attackCooldownTimer <= 0.0f)
                {
                    _activeState = EnemyStatesActive.Attack;
                    Vector3 dir = (player.GlobalPosition - GlobalPosition).Normalized();
                    dir.Y = 0.0f;

                    UpdateSprite(dir);
                }
                else if (distanceToPlayer > _patrolRadius)
                {
                    ExitCombat();
                }

                if (_attackCooldownTimer > 0.0f)
                {
                    _attackCooldownTimer -= (float)delta;
                }
                break;

            case EnemyStatesActive.Attack:
                Vector3 velocity = velocity;
                velocity.X = 0.0f;
                velocity.Z = 0.0f;

                Velocity = velocity;

                if (!_attackLanded && _attackTimer >= _attackDuration * 0.5f)
                {
                    _attackLanded = true;
                }

                if (_attackTimer >= _attackDuration)
                {
                    _attackTimer = 0.0f;
                    _attackLanded = false;
                    _attackCooldownTimer = _attackCooldown;
                    _activeState = EnemyStatesActive.Chase;
                }

                break;

            case EnemyStatesActive.Heal:
                ActiveHeal();
                break;

            case EnemyStatesActive.Run:
                break;

            default:
                break;
        }
    }

    public void ActiveHeal()
    {
        _activeState = EnemyStatesActive.Chase;
        if (Hp < (0.1f * MaxHp) && GD.Randf() > 0.3f)
        {
            Hp = min(Hp + 100.0f, MaxHp);
        }
    }

    private void EnterWatch(
        float duration = _waitTime,
        bool returnHome = false
    )
    {
        _passiveState = EnemyStatesPassive.Watch;

        _watchTimer = 0.0f;
        _watchDuration = duration;
        _returningHome = returnHome;

        Vector3 velocity = velocity;
        velocity.X = 0.0f;
        velocity.Z = 0.0f;

        Velocity = velocity;
    }

    private float HorizontalDistanceToPlayer()
    {
        Vector3 offset = player.GlobalPosition - GlobalPosition;
        offset.Y = 0.0f;
        return offset.Length();
    }

    private float HorizontalDistanceToSpawn()
    {
        Vector3 offset = _spawnPosition - GlobalPosition;
        offset.Y = 0.0f;
        return offset.Length();
    }

    private void ResolveWatch(
        float distanceToPlayer,
        float distanceToSpawn
    )
    {
        if (distanceToPlayer < _investigationRadius)
        {
            _returningHome = false;
            _passiveState = EnemyStatesPassive.Investigate;
        }
        else if (distanceToSpawn > _patrolRadius)
        {
            _passiveState = EnemyStatesPassive.Disengage;
        }
        else if (distanceToPlayer < _detectionRadius)
        {
            _passiveState = EnemyStatesPassive.SlowPatrol;
        }
        else
        {
            PickNewPatrolPoint();
            _passiveState = EnemyStatesPassive.Patrol;
        }
    }

    public void EnterCombat()
    {
        if (_inCombat)
        {
            return;
        }

        _inCombat = true;
        ResourceBarVisibility();
    }

    public void ExitCombat()
    {
        if (!_inCombat)
        {
            return;
        }

        _inCombat = false;
        ResourceBarVisibility();

        CombatManager.Instance.ExitCombat(this);
        EnterWatch(5.0, true);
    }

    private bool WalkRoutine(float moveSpeed)
    {
        Vector3 toTarget = _moveTarget = GlobalPosition;
        toTarget.Y = 0.0f;

        float distance = toTarget.Length();

        if (distance <= WaypointReachedDistance)
        {
            Vector3 position = GlobalPosition;
            position.X = _moveTarget.X;
            position.Z = _moveTarget.Z;

            GlobalPosition = position;

            Vector3 velocity = velocity;
            velocity.X = 0.0f;
            velocity.Z = 0.0f;

            Velocity = velocity;

            UpdateSprite(Vector3.Zero);
            return true;
        }

        Vector3 direction = toTarget.Normalized();
        Velocity = new Vector3(
            direction.X * moveSpeed,
            0.0f,
            direction.Y * moveSpeed
        );

        UpdateSprite(direction);
        return false;
    }

    private void PickNewPatrolPoint()
    {
        float randomAngle = GD.Randf() * Mathf.Tau;
        float randomDistance = Mathf.Sqrt(GD.Randf()) * _patrolRadius;

        _moveTarget = _spawnPosition + Vector3(
            Mathf.cos(randomAngle) * randomDistance,
            0,
            Mathf.sin(randomAngle) * randomDistance
        );
    }

    private void ChasePlayer(float distance, float moveSpeed)
    {
        if (distance > AttackRange)
        {
            Vector3 targetDir = (player.GlobalPosition - GlobalPosition).Normalized();
            Velocity = new Vector3(
                targetDir.X * moveSpeed,
                0.0f,
                targetDir.Z * moveSpeed
            );
            UpdateSprite(targetDir);
        }
        else
        {
            Velocity = new Vector3(0, 0, 0);
            UpdateSprite(Vector3.Zero);
        }
    }

    public void UpdateSprite(Vector3 moveDir)
    {
        Vector2 horizontalDir = Vector2(
            moveDir.X,
            moveDir.Z
        );

        if (horizontalDir.X > 0.01f)
        {
            _facingRight = true;
        }
        else if (horizontalDir.X < -0.01f)
        {
            _facingRight = false;
        }

        _sprite.FlipH = !_facingRight;

        if (horizontalDir.Length())
        {
            if (_inCombat)
            {
                _sprite.Play("run");
            }
            else
            {
                _sprite.Play("walk");
            }
        }
        else
        {
            _sprite.Play("idle");
        }

        if (_activeState == EnemyStatesActive.Attack)
        {
            _sprite.Play("attack");
        }
    }

    private void ResourceBarTransition(double delta)
    {
        float _targetHpPct = Hp / MaxHp;
        float _targetSpPct = Sp / MaxSp;

        _displayedHpPct = Mathf.MoveToward(
            _displayedHpPct,
            _targetHpPct,
            _barSmoothSpeed * (float)delta
        );

        _displayedSpPct = Mathf.MoveToward(
            _displayedSpPct,
            _targetSpPct,
            _barSmoothSpeed * (float)delta
        );

        UpdateHPBar();
        UpdateSPBar();
    }

    private void ResourceBarVisibility(string text = "Enemy")
    {
        _resourceBars.Visible = (_inCombat || _isHovered;)
    }

    private void UpdateHPBar()
    {
        _hpBarMaterial.SetShaderParameter(
            "fill_amount",
            _displayedHpPct
        );
    }

    private void UpdateSPBar()
    {
        _spBarMaterial.SetShaderParameter(
            "fill_amount",
            _displayedSpPct
        );
    }

}