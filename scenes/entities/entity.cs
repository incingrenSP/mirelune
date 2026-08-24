using Godot;

public partial class Entity : CharacterBody3D
{
	[Export]
	protected float MaxHp { get; set; } = 100.0f;
	
	protected float _hp;
	
	public float Hp
	{
		get => _hp;
		set => _hp = Mathf.Clamp(value, 0.0f, MaxHp);
	}

	protected float _displayedHpPct = 1.0f;
	protected float _displayedSpPct = 1.0f;

	[Export]
	protected float _barSmoothSpeed = 2.5f;

	[Export]
	protected Marker3D FocusPoint;

	public override _Ready()
	{
		FocusPoint = GetNode<Marker3D>("CameraFocusPoint");

		Hp = MaxHp;
	}
}
