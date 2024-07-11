import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/spacer.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home/settings/prop_pref_components/location_prop_pref.dart';
import 'package:client/pages/home/swipe/user_gender.dart';
import 'package:client/utils/prefs_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserDetails extends StatelessWidget {
  final bool isCardExpanded;
  final Function toggleCard;
  final ApiUser user;

  const UserDetails({
    super.key,
    required this.isCardExpanded,
    required this.toggleCard,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);
    var me = userModel.me;
    var meLatI16 = getPropByName(me.props, "latitude").value;
    var meLngI16 = getPropByName(me.props, "longitude").value;
    var otherLatI16 = getPropByName(user.props, "latitude").value;
    var otherLngI16 = getPropByName(user.props, "longitude").value;

    var (meLat, meLng) = decodeLatLongFromI16(meLatI16, meLngI16);
    var (otherLat, otherLng) = decodeLatLongFromI16(otherLatI16, otherLngI16);
    var distance = calcDistanceKm(meLat, meLng, otherLat, otherLng).round();
    if (distance < 1) {
      distance = 1;
    }

    return GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy < 0) {
            toggleCard();
          } else if (details.velocity.pixelsPerSecond.dy > 0) {
            toggleCard();
          }
        },
        child: Card(
          elevation: 5.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
          ),
          //no margin
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isCardExpanded ? 200.0 : 60.0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => toggleCard(),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GenderDisplay(
                          maleValue: (getPropByName(user.props, "percent_male")
                                  .value as double) /
                              100.0,
                          femaleValue:
                              (getPropByName(user.props, "percent_female").value
                                      as double) /
                                  100.0,
                        ),
                        const HorizontalSpacer(size: SpacerSize.small),
                        Text(
                          "${user.displayName}, ${getPropByName(user.props, "age").value}",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const HorizontalSpacer(size: SpacerSize.small),
                        Icon(
                          isCardExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isCardExpanded)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  "Distance: $distance km",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const HorizontalSpacer(
                              size: SpacerSize.small,
                            ),
                            Text(
                              user.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }
}
