using Godot;

public partial class Entity : CharacterBody3D
{
	[Export]
	public float MaxHp { get; set; } = 100.0f;
	
	private float _hp;
	
	public float Hp
	{
		get => _hp;
		set => _hp = Mathf.Clamp(value, 0.0f, MaxHp);
	}

	private float _displayedHpPct = 1.0f;
	private float _displayedSpPct = 1.0f;

	[Export]
	private float _barSmoothSpeed = 2.5f;

	[Export]
	private Marker3D FocusPoint;

	public override _Ready()
	{
		FocusPoint = GetNode<Marker3D>("CameraFocusPoint");

		Hp = MaxHp;
	}
}
