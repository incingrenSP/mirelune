using Godot;

public partial class CameraController : Node3D
{
    [Export]
    private SpringArm3D _springArm;

    [Export]
    private float _dialogZoomSpeed = 3.0f;
    [Export]
    private float _dialogDistance = 6.0f;

    [Export]
    private float _defaultDistance = 8.0f;
    [Export]
    private float _followSpeed = 5.0f;

    public Marker3D DefaultTarget { get; private set;}
    public Marker3D FocusTarget { get; private set; }

    private Vector3 _focusOffset = Vector3.Zero;
    private float _targetSpringLength;

    public override void _Ready()
    {
        _springArm = GetNode<SpringArm3D>("SpringArm3D");
        AddToGroup("camera");

        DialogManager.Instance.RegisterCamera(this);
        _targetSpringLength = _defaultDistance;
        _springArm.SpringLength = _defaultDistance;
    }

    public override void _Process(double delta)
    {
        Marker3D target = (FocusTarget != null)?FocusTarget:DefaultTarget;
        if (target != null)
        {
            Vector3 desiredPosition = target.GlobalPosition + _focusOffset;
            float weight = 1.0f - Mathf.Exp(-_followSpeed * (float)delta);

            GlobalPosition = GlobalPosition.Lerp(
                desiredPosition,
                weight
            );
        }
        _springArm.SpringLength = Mathf.MoveToward(
            _springArm.SpringLength,
            _targetSpringLength,
            _dialogZoomSpeed * (float)delta
        );
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (FocusTarget != null)
        {
            return;
        }
    }

    public void SetDefaultTarget(Marker3D target)
    {
        DefaultTarget = target;
    }

    public void FocusOn(Marker3D target, Vector3 offset = default)
    {
        FocusTarget = target;
        _focusOffset = offset;
        _targetSpringLength = _dialogDistance;
    }

    public void ReleaseFocus()
    {
        FocusTarget = null;
        _focusOffset = Vector3.Zero;
        _targetSpringLength = _defaultDistance;
    }
}