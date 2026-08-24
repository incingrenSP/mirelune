using Godot;

public partial class DialogLogEntry : PanelContainer
{
	[Export]
	private Label SpeakerLabel { get; set; }
	[Export]
	private Label TextLabel { get; set; }
	[Export]
	private VBoxContainer EntryVBox { get; set; }

	public override void _Ready()
	{
		SpeakerLabel = GetNode<Label>("MarginContainer/VBoxContainer/SpeakerLabel");
		TextLabel = GetNode<Label>("MarginContainer/VBoxContainer/TextLabel");
		EntryVBox = GetNoce<VBoxContainer>("MarginContainer/VBoxContainer");
	}

	public void Setup(string pSpeaker, string pDialog)
	{
		SpeakerLabel.Text = pSpeaker;
		TextLabel.Text = pDialog;
		TextLabel.AutowrapMode = TextServer.AutowrapWord;

		EntryVBox.SizeFlagsHorizontal = Control.SizeExpanFull;
	}
}
