using Godot;

public partial class PlayerInteractionArea : InteractionArea
{
	[Export]
	public Player player { get; private set; }
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
		_hovered = value;

		if (player != null)
		{
			player.SetHoverState(value);
			player.ResourceBarVisibility();
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
		if (inputEvent is InputEventMouseButton mouseButton && mouseButton.Pressed)
		{
			if (mouseButton.ButtonIndex == mouseButton.Left)
			{
				if (!GameStateManager.IsDialogActive())
				{
					GD.Print(">>>> PLAYER CLICKED");
					player.RequestPause();
				}
			}
			else if(mouseButton.ButtonIndex == mouseButton.Right)
			{
				GD.Print("10 damage taken");
				GD.Print($"Player currently has: {player.TakeDamage(10)}");
			}
		}
	}
}
