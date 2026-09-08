// vehicle_select_screen.dart — SAFE//SPIT
//
// Screen to select the active vehicle profile (Phase 8).
// Updates GameState.vehicle on selection.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_state.dart';
import '../simulation/vehicle_profiles.dart';
import '../hud/missile_lock_reticle_painter.dart'; // for colors

class VehicleSelectScreen extends StatelessWidget {
  const VehicleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final currentVehicle = gameState.vehicle;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: kTacticalGreen),
        title: const Text(
          'SELECT VEHICLE',
          style: TextStyle(
            color: kTacticalGreen,
            fontFamily: 'SpaceMono',
            fontSize: 16,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Green tint
          Container(color: kTacticalGreen.withValues(alpha: 0.02)),
          
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: VehicleProfiles.all.length,
            itemBuilder: (context, index) {
              final vehicle = VehicleProfiles.all[index];
              final isSelected = vehicle.id == currentVehicle.id;
              
              return GestureDetector(
                onTap: () {
                  context.read<GameState>().selectVehicle(vehicle);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? kTacticalGreen.withValues(alpha: 0.15) 
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? kTacticalGreen 
                          : kTacticalGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.displayName.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? kTacticalGreen : kTacticalGreen.withValues(alpha: 0.8),
                              fontFamily: 'SpaceMono',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TURBULENCE: ${vehicle.turbulenceFactor.toStringAsFixed(2)}x\n'
                            'WIND SENS : ${vehicle.windSensitivity.toStringAsFixed(2)}x\n'
                            'DIFFICULTY: ${(vehicle.difficulty * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: kTacticalGreen.withValues(alpha: 0.6),
                              fontFamily: 'SpaceMono',
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_outline,
                          color: kTacticalGreen,
                          size: 32,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
