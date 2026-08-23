using Godot;

public partial class entity : CharacterBody3D
{
	[Export]
	public float MaxHp { get; set; } = 100.0f;
	
	private float _hp;
	
	public float Hp
	{
		get => _hp;
		set => _hp = Mathf.Clamp(value, 0.0f, MaxHp);
	}

	public float DisplayedHpPct { get; set; } = 1.0f;
	public float DisplayedSpPct {get; set; } = 1.0f;

	[Export]
	private Marker3D FocusPoint;

	public override _Ready()
	{
		FocusPoint = GetNode<Marker3D>("CameraFocusPoint");

		Hp = MaxHp;
	}
}
