using Godot;

public partial class DialogLine : RefCounted
{
    public DialogLine Instance { get; private set; }

    public string Speaker;
    public string Text;
    public Marker3D Target;

    public override void _Ready()
    {
        Instance = this;
    }

    public DialogLine(string SpeakerName, string DialogText, Marked3D FocusTarget = null)
    {
        Speaker = SpeakerName;
        Text = DialogText;
        Target = FocusTarget;
    }
}