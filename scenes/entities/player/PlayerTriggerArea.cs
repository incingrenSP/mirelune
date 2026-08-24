using Godot;
using System;
using System.Collections.Generic;

public partial class PlayerTriggerArea : Area3D
{
	private List<Interactable> _nearbyInteractable = new();

	public override void _Ready()
	{
		AreaEntered += OnAreaEntered;
		AreaExited += OnAreaExited;
	}

	private void OnAreaEntered(Area3D area)
	{
		if (area is Interactable)
		{
			GD.Print($">>>>> INTERACTABLE ENTERED: {area.Name}");

			if (!_nearbyInteractable.Contains(area))
			{
				_nearbyInteractable.Add(area);
				GD.Print($">>>>> Added Interactable. Count: {_nearbyInteractable.Count}");
			}
			else
			{
				GD.Print("Not an interactable");
			}
		}
	}

	private void OnAreaExited(Area3D area)
	{
		GD.Print("====PLAYER TRIGGER ON AREA EXITED====");
		if (area is Interactable)
		{
			if (_nearbyInteractable.Contains(area))
			{
				_nearbyInteractable.Remove(area);

				GD.Print($">>>>> Removed interacable. Count: {_nearbyInteractable.Count}");
			}
		}
	}
}
