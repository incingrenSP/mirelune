using Godot;

public partial class EnemyInteractionArea : InteractionArea
{
    [Export]
    private Enemy enemy { get; set; }

    public override void _Ready()
    {
        base._Ready();

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
        if (GameStateManager.Instance.IsDialogActive())
        {
            return;
        }

        _hovered = value;

        if (enemy != null)
        {
            GD.Print("Enemy Detected!");
            enemy._isHovered = value;
            enemy.ResourceBarVisibility();
        }
    }

    private void OnInputEvent(
        CameraController camera,
        InputEvent inputEvent,
        Vector3 position,
        Vector3 normal,
        int shapeIdx
    )
    {
        if (inputEvent is InputMouseButton mouseButton && mouseButton.Pressed)
        {
            if (mouseButton.ButtonIndex == mouseButton.Left)
            {
                GD.Print("Enemy took 10 damage");
                GD.Print($"Enemy currently has: {enemy.TakeDamage(10)}");
            }
        }
    }
}