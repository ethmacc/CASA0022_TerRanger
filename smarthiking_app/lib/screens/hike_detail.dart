import 'package:flutter/material.dart';
import 'package:smarthiking_app/widgets/bottom_navbar.dart';
import 'package:smarthiking_app/models/db_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smarthiking_app/screens/enter_hike.dart';
import 'package:smarthiking_app/models/active_hike.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';

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

  Future<List<LatLng>> getSampleCoords(int hikeId) async {
    List<LatLng> coords = [];
    List<Map> samples = await getSamplesByID(hikeId);
    for (var i = 0; i < samples.length; i ++) {
      LatLng coord = LatLng(samples[i]['lat'], samples[i]['long']);
      coords.add(coord);
    }
    return coords;
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
        future: Future.wait([getHikeByID(widget.hikeID), getSampleCoords(widget.hikeID)]), 
        builder: (context, allData) {
            ActiveHike activeHike = Provider.of<ActiveHike>(context, listen:false);
            bool isHikeActive = activeHike.isHikeActive(widget.hikeID);
            Map hikeData = Map.from(allData.data?[0][0]as Map<Object?, Object?>);
            List<LatLng> routeCoords = List.from(allData.data?[1]as List<LatLng>);

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
                      '${hikeData['name']}',
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
                      'Start Date & Time:',// ${hikeData.data?[0]['date']}',
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
                        CurrentLocationLayer(
  
                        ),
                        PolylineLayer(
                          polylines: routeCoords.isNotEmpty ? [Polyline(
                            points: routeCoords,
                            color: Colors.blue,
                            strokeWidth: 5,
                            )] :
                          <Polyline<Object>> []),
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
                            Text('${hikeData['distance']} km',
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
                          Text('${hikeData['elevation']} ft',
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
                      ),
                TextButton(
                              onPressed: () async {
                                Position currentPosition = await Geolocator.getCurrentPosition();
                                debugPrint('$currentPosition');
                                int newSampleId = await getLatestID('samples');
                                setState(() {
                                  insertSample(Sample(id: newSampleId, hikeId: widget.hikeID, tofData: 'TEST', lat: currentPosition.latitude, long:currentPosition.longitude));
                                });
                              }, 
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll<Color>(Colors.green),
                                foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                                ),
                              child: Text('TEST: add position'),
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