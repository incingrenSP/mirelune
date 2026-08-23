using Godot;

public partial class Player : Entity
{
    private const float WalkSpeed =  4.0f;
    private const float RunSpeed = 10.0f;
    private const float Gravity = 18.0f;
    private const float InteractTimeout = 0.5f;

    private bool _facingRight = true;
    private float _interactTimer = 0.0f;

    private AnimatedSprite3D _sprite;
    [Export]
    private Node2D _pauseMenu;
    [Export]
    private Area3D _playerTriggerArea;
    [Export]
    private Node3D _camera;
    private Node3D _worldUI;
    private MeshInstance3D _hpBar;
    private MeshInstance3D _spBar;

    private bool _isHovered = false;
    private bool _inputLocked = false;
    private bool _inCombat = false;

    [Export]
    public string PlayerName { get; set; } = "Player";
    [Export]
    public int PlayerLevel { get; set; } = 1;

    [Export]
    public float Sp { get; set; } = 0.0f;
    [Export]
    public float MaxSp { get; set; } = 100.0f;

    [Export]
    public float HpRegenRate { get; set; } = 0.0f;
    [Export]
    public float SpRegenRate { get; set; } = 5.0f;


    public override void _Ready()
    {
        base._Ready();
        
        _sprite = GetNode<AnimatedSprite3D>("Visual/AnimatedSprite3D");
        _worldUI = GetNode<Node3D>("WorldUI");
        _hpBar = GetNode<MeshInstance3D>("WorldUI/ResourceBards/HPBarFG");
        _spBar = GetNode<MeshInstance3D>("WorldUI/ResourceBards/SPBarFG");

        _hpBarMaterial = _hpBar.MaterialOverride as ShaderMaterial;
        _spBarMaterial = _spBar.MaterialOverride as ShaderMaterial;

        var cam = GetTree().GetFirstNodeInGroup("camera") as CameraController;

        if (cam != null)
        {
            cam.SetDefaultTarget(FocusPoint);
        }
        DialogManager.Instance.DialogFinished += OnDialogFinished;

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

        if (GameStateManager.Instance.IsDialogActive())
        {
            _inputLocked = true;
        }
        else
        {
            _inputLocked = false;
        }

        Vector2 inputDir = Vector2.Zero;

        if (!_inputLocked)
        {
            inputDir = Vector2(
                Input.GetActionStrength("move_right") - Input.GetActionStrength("move_left"),
                Input.GetActionStrength("move_forward") - Input.GetActionStrength("move_backward")
            );
        }
        Vector3 forward = -_camera.GlobalTransform.Basis.Z;
        forward.Y = 0;
        forward = forward.Normalized();

        Vector3 right = _camera.GlobalTransform.Basis.X;
        right.Y = 0;
        right = right.Normalized();

        Vector3 direction = (
            forward * inputDir.Y + right * inputDir.X
        ).Normalized();

        if (direction != Vector3.Zero)
        {
            float angle = Mathf.Atan2(direction.X, direction.Z);
            Rotation = new Vector3(
                Rotation.X,
                Mathf.LerpAngle(
                    Rotation.Y,
                    angle,
                    (float)delta * 10.0f
                ),
                Rotation.Z
            );
        }

        float speed = WalkSpeed;

        if (Input.IsActionPressed("run"))
        {
            speed = RunSpeed;
        }

        Velocity = new Vector3(
            direction.X * speed,
            Velocity.Y,
            direction.Z * speed
        );

        UpdateSprite(inputDir);
        MoveAndSlide();
    }

    public override void _Process(double delta)
    {
        if (!InCombat)
        {
            if (Hp < MaxHp)
            {
                Hp = Mathf.Min(Hp + HpRegenRate * (float)delta, MaxHp);
            }
            if (Sp < MaxSp)
            {
                Sp = Mathf.Min(Sp + SpRegenRate * (float)delta, MaxSp);
            }
        }

        if (_interactTimer > 0.0f)
        {
            _interactTimer -= (float)delta;
        }

        _resourceBarTransition();
    }
    
    public override void _InputEvent(InputEvent @event)
    {
        return;
    }

    public void TryToInteract(Interactable target)
    {
        GD.Print("====================================");
        GD.Print("PLAYER TRY TO INTERACT");
    }

    public void UpdateSprite(Vector2 inputDir)
    {
        if (inputDir.X > 0)
        {
            _facingRight = true;
        }
        else if (inputDir.X < 0)
        {
            _facingRight = false;
        }

        _sprite.FlipH = !_facingRight;

        bool moving = (inputDir != Vector2.Zero)?true:false;

        if (moving)
        {
            if (Input.IsActionPressed("run")){
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
    }

    private void OnDialogFinished()
    {
        _interactTimer = InteractTimeout;
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

    public void SetCombatState(bool value)
    {
        _inCombat = value;

        ResourceBarVisibility();
    }

    private void ResourceBarVisibility()
    {
        _worldUI.Visibile = (_inCombat || _isHovered);
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

    public void RequestPause()
    {
        // PauseMenu.Open();
        return;
    }

}
