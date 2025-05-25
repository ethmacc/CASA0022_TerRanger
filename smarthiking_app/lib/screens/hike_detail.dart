import 'package:flutter/material.dart';
import 'package:smarthiking_app/widgets/bottom_navbar.dart';
import 'package:smarthiking_app/models/db_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smarthiking_app/screens/enter_hike.dart';
import 'package:smarthiking_app/models/active_hike.dart';
import 'package:provider/provider.dart';

class HikeDetail extends StatefulWidget {
  const HikeDetail({super.key, required this.hikeID});
  final int hikeID;

  @override
  State<HikeDetail> createState() => _HikeDetailState();
}

class _HikeDetailState extends State<HikeDetail> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Hike Details'),
      ),
      bottomNavigationBar: BottomNavbar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EnterHike())
            );
        },
        child: Icon(Icons.add)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      body: FutureBuilder(
        future: getHikeByID(widget.hikeID), 
        builder: (context, hikeData) {
            ActiveHike activeHike = Provider.of<ActiveHike>(context, listen:false);
            bool isHikeActive = activeHike.isHikeActive(widget.hikeID);

            return Column(
              children: [
                isHikeActive ? ListTile(
                  leading: Icon(Icons.radio_button_checked, 
                    color: Colors.red,), 
                  title: Text('This hike is currently active'),
                  trailing: TextButton(onPressed: () {
                    activeHike.deactivateHike();
                    setState(() {
                      isHikeActive = activeHike.isHikeActive(widget.hikeID);
                    });
                  }, child: Text('deactivate')),
                  ) : 
                ListTile(
                  leading: Icon(Icons.radio_button_unchecked,
                    color: Colors.grey,
                  ),
                  title: Text('This hike is not active'),
                  trailing: TextButton(onPressed: () {
                    activeHike.activateHike(widget.hikeID);
                    setState(() {
                      isHikeActive = activeHike.isHikeActive(widget.hikeID);
                    });
                  }, child: Text('activate')),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child:  Text(
                      '${hikeData.data?[0]['name']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 32.0,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                    child:  Text(
                      'Start Date & Time: ${hikeData.data?[0]['date']}',
                      style: TextStyle(
                        fontSize: 15.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.height / 3,
                    width: MediaQuery.of(context).size.width / 10 * 9,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(51.5072, 0.1276),
                        initialZoom: 9.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        RichAttributionWidget(attributions: [
                          TextSourceAttribution('OpenStreetMap contributors')
                        ])
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 5),
                      child: Column(
                          children: [
                            Text('Distance'),
                            Text('${hikeData.data?[0]['distance']} km',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                            )
                          ],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 5),
                      child: Column(
                        children: [
                          Text('Max Elevation'),
                          Text('${hikeData.data?[0]['elevation']} ft',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                            )
                        ],
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 5),
                      child: Column(
                        children: [
                          Text('Data samples'),
                          Text('0', // TODO: Add sample count from db sample table
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                            ),
                        ],
                      )
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child:
                    TextButton(
                              onPressed: () {
                                //TODO: add route to data viewer
                              }, 
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll<Color>(Colors.grey),
                                foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                                ),
                              child: Text('View data samples >'),
                              )
                )
                  ],
                )
              ],
            );
          }
        ),
      );
    }
}