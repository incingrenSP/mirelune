using Godot;

public partial class Interactable : InteractionArea
{
    [Export]
    private Player player { get; set; }
    [Export]
    private NPC npc { get; set; }

    private int _timesHovered = 0;
    private bool _hovered = false;

    private string _testText = "Lorem ipsum dolor sit amet consectetur adipiscing elit.";

    public override void _Ready()
    {
        player = GetTree().GetFirstNodeInGroup("player");

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

    public void SetHovered(bool value)
    {
        _hovered = value;

        if (_hovered)
        {
            GD.Print("Hovering NPC");
        }

        if (npc != null)
        {
            npc.ShowName(value);
        }
    }

    public override void OnInputEvent(
        CameraController camera,
        InputEvent inputEvent,
        Vector3 position,
        Vector3 normal,
        int shapeIdx
    )
    {
        if(inputEvent is InputEventMouseButton mouseButton && mouseButton.Pressed)
        {
            if(mouseButton.ButtonIndex == mouseButton.Left)
            {
                player.TryToInteract(this);
            }
        }
    }

    public void Interact()
    {
        GD.Print("====NPC INTERACT====");
        GD.Print("Interact was called");

        if (GameStateManager.Instance.IsDialogActive())
        {
            GD.Print("Game is currently in active dialog state.");
            return;
        }

        if (CombatManager.Instance.IsInCombat())
        {
            GD.Print("Game is currently in active combat state.");
            return;
        }

        StartDialog();
    }

    public void StartDialog()
    {
        List<DialogLine> lines = [
            new DialogLine(
                "NPC",
                "May I help you?",
                npc.FocusPoint
            ),
            new DialogLine(
                "Player",
                "No.",
                player.FocusPoint
            ),
            new DialogLine(
                "NPC",
                "Alright, have fun!",
                npc.FocusPoint
            )
        ];

        GD.Print("NPC Dialog has been loaded.");
        DialogManager.Instance.StartDialog(lines);
    }
}