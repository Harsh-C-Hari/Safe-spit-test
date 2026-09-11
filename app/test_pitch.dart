import 'dart:math' as math;
void main() {
  print('Face Up (Z=9.8, Y=0): ${math.atan2(9.8, 0) * 180 / math.pi + 90}');
  print('Face Down (Z=-9.8, Y=0): ${math.atan2(-9.8, 0) * 180 / math.pi + 90}');
}
