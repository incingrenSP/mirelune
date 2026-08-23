using Godot;

public partial class InteractionArea : Area3D
{
    private int _timesHovered = 0;
    private bool _hovered = false;

    public override void _Ready()
    {
        MouseEntered += OnMouseEntered;
        MouseExited += OnMouseExited;
        InputEvent += OnInputEvent;
    }

    private void OnMouseEntered()
    {
        SetHovered(true);
    }

    private void OnMouseExited()
    {
        SetHovered(false);
    }

    private void SetHovered(bool value)
    {
        _hovered = value;
    }

    private void OnInputEvent(
        CameraController camera,
        InputEvent inputEvent,
        Vector3 position,
        Vector3 normal,
        int shapeIdx
        )
    {
        if (inputEvent is InputEventMouseButton mouseButton)
        {
            pass;
        }
    }
}