using Godot;

public partial class NPC : Entity
{
    [Export]
    private AnimatedSprite3D _sprite;
    [Export]
    private bool _routineEnabled = true;
    [Export]
    public Node3D RoutinePointA;
    [Export]
    public Node3D RoutinePointB;
    [Export]
    private float _waitTime = 10.0f;
    [Export]
    private float _detectionRadius = 10.0f;

    private const float WalkSpeed = 4.0f;
    private const float Gravity = 18.0f;

    private bool _facingRight = true;
    private bool _inDialog = false;
    private Vector3 _moveTarget;

    private bool _waiting = false;
    private int _routineDirection = 1;

    public Label3D NpcNameLabel;


    public override void _Ready()
    {
        base._Ready();

        _sprite = GetNode<AnimatedSprite3D>("Visual/AnimatedSprite3D");
        NpcNameLabel = GetNode<Label>("WorldUI/Label3D");

        DialogManager.Instance.DialogTargetChanged += OnDialogTargetChanged;

        if (_routineEnabled)
        {
            _moveTarget = RoutinePointB.GlobalPosition;
        }
    }

    public override void _PhysicsProcess(double delta)
    {
        if (!IsOnFloot())
        {
            Velocity = new Vector3(
                Velocity.X,
                Velocity.Y - Gravity * (float)delta,
                Velocity.Z
            );
        }
        else
        {
            Velocity = new Vector3(
                Velocity.X,
                0.0f,
                Velocity.Z
            );
        }

        if (GameStateManager.Instance.IsDialogActive())
        {
            ShowName();
            Velocity = new Vector3(0, 0, 0);
            UpdateSprite(Vector3.Zero);
        }

        else if (RoutineEnabled)
        {
            WalkRoutine();
        }
        else
        {
            Velocity = new Velocity(0, 0, 0);
            UpdateSprite(Vector.Zero);
        }

        MoveAndSlide();
    }

    private void OnDialogTargetChanged(Node3D target)
    {
        _inDialog = (target == this);
    }

    private void WalkRoutine()
    {
        if (_waiting)
        {
            Velocity = new Vector3(0, 0, 0);
            UpdateSprite(Vector3.Zero);
            return;
        }

        Vector3 distanceToTarget = GlobalPosition.DistanceTo(_moveTarget);

        if (distanceToTarget < 1.0)
        {
            Velocity = new Vector3(0, 0, 0);
            UpdateSprite(Vector3.Zero);
            StartWaiting();
            return;
        }

        Vector3 direction = GlobalPosition.DirectionTo(_moveTarget);
        direction = new Vector3(
            direction.X,
            0,
            direction.Z
        ).Normalized();

        Velocity = new Vector3(
            direction.X * WalkSpeed,
            0,
            directionZ * WalkSpeed
        );

        UpdateSprite(direction);
    }

    private void start_waiting()
    {
        if (_waiting)
        {
            return;
        }

        _waiting = true;
        await ToSignal(
            GetTree().CreateTimer(_waitTime),
            SceneTreeTimer.SignalName.Timeout
        );

        if (_routineDirection == 1)
        {
            _routineDirection = -1;
            _moveTarget = RoutinePointA.GlobalPosition;
        }
        else
        {
            _routineDirection = 1;
            _moveTarget = RoutinePointB.GlobalPosition;
        }

        _waiting = false;
    }

    public void UpdateSprite(Vector3 moveDir)
    {
        Vector2 horizontalDir = Vector2(moveDir.x, moveDir.Z);

        if (horizontalDir.X > 0.01f)
        {
            _facingRight = true;
        }
        else if (horizontalDir.X < -0.01f)
        {
            _facingRight = false;
        }

        _sprite.FlipH = !_facingRight;

        if (horizontalDir.Length() > 0.01f)
        {
            _sprite.Play("walk");
        }
        else
        {
            _sprite.Play("idle");
        }
    }

    public void ShowName(bool visibleState = false)
    {
        NpcNameLabel.Text = "NPC";
        NpcNameLabel.Visible = (visibleState || GameStateManager.Instance.IsDialogActive());
    }

}