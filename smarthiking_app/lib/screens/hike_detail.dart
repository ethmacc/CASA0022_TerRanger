import 'package:flutter/material.dart';
import 'package:smarthiking_app/models/conn_manager.dart';
import 'package:smarthiking_app/widgets/bottom_navbar.dart';
import 'package:smarthiking_app/models/db_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smarthiking_app/screens/enter_hike.dart';
import 'package:smarthiking_app/screens/sample_detail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class HikeDetail extends StatefulWidget {
  const HikeDetail({super.key, required this.hikeID, required this.initialMaps, required this.initalHike});
  final int hikeID;
  final List<Map> initialMaps;
  final Map initalHike;

  @override
  State<HikeDetail> createState() => _HikeDetailState();
}

class _HikeDetailState extends State<HikeDetail> with TickerProviderStateMixin{
  late MapController _mapController;
  late Position initialPos;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  LatLngBounds getRouteBounds (List<LatLng> routeCoords) {
    //derived from VitList's answer on StackOverflow (https://stackoverflow.com/questions/57986855/center-poly-line-google-maps-plugin-flutter-fit-to-screen-google-map)
    double minLat = routeCoords.first.latitude;
    double minLong = routeCoords.first.longitude;
    double maxLat = routeCoords.first.latitude;
    double maxLong = routeCoords.first.longitude;

    for (var i = 0; i < routeCoords.length; i ++) {
      if(routeCoords[i].latitude < minLat) minLat = routeCoords[i].latitude;
      if(routeCoords[i].latitude > maxLat) maxLat = routeCoords[i].latitude;
      if(routeCoords[i].longitude < minLong) minLong = routeCoords[i].longitude;
      if(routeCoords[i].longitude > maxLong) maxLong = routeCoords[i].longitude;
    }

    LatLng startCoord = LatLng(minLat, minLong);
    LatLng endCoord = LatLng(maxLat, maxLong);
    LatLngBounds bounds = LatLngBounds(startCoord, endCoord);
    return bounds;
  }

  //derived from animated_map_controller by JaffaKetchup on GitHub
  void moveMapToRouteBounds (List<LatLng> routeCoords) {
    double minLat = routeCoords.first.latitude;
    double minLong = routeCoords.first.longitude;
    double maxLat = routeCoords.first.latitude;
    double maxLong = routeCoords.first.longitude;

    //derived from VitList's answer on StackOverflow (https://stackoverflow.com/questions/57986855/center-poly-line-google-maps-plugin-flutter-fit-to-screen-google-map)
    for (var i = 0; i < routeCoords.length; i ++) {
      if(routeCoords[i].latitude < minLat) minLat = routeCoords[i].latitude;
      if(routeCoords[i].latitude > maxLat) maxLat = routeCoords[i].latitude;
      if(routeCoords[i].longitude < minLong) minLong = routeCoords[i].longitude;
      if(routeCoords[i].longitude > maxLong) maxLong = routeCoords[i].longitude;
    }

    LatLng startCoord = LatLng(minLat, minLong);
    LatLng endCoord = LatLng(maxLat, maxLong);

    if (Point(startCoord.latitude, startCoord.longitude).distanceTo(Point(endCoord.latitude, endCoord.longitude)) > 0) {
      LatLngBounds bounds = LatLngBounds(startCoord, endCoord);

      // Create some tweens. These serve to split up the transition from one location to another.
      // In our case, we want to split the transition be<tween> our current map center and the destination.
      final northTween = Tween<double>(
        begin: _mapController.camera.visibleBounds.north, end: bounds.north);
      final eastTween = Tween<double>(
        begin: _mapController.camera.visibleBounds.east, end: bounds.east);
      final southTween = Tween<double>(
        begin: _mapController.camera.visibleBounds.south, end: bounds.south);
      final westTween = Tween<double>(
        begin: _mapController.camera.visibleBounds.west, end: bounds.west);

      // Create a animation controller that has a duration and a TickerProvider.
      final controller = AnimationController(
          duration: const Duration(milliseconds: 500), vsync: this);
      // The animation determines what path the animation will take. You can try different Curves values, although I found
      // fastOutSlowIn to be my favorite.
      final Animation<double> animation =
          CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);
      controller.addListener(() {
        _mapController.fitCamera(
            CameraFit.bounds(bounds: LatLngBounds(
                LatLng(southTween.evaluate(animation), westTween.evaluate(animation)),
                LatLng(northTween.evaluate(animation), eastTween.evaluate(animation))
                )
              )
            );
      });

      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.dispose();
        } else if (status == AnimationStatus.dismissed) {
          controller.dispose();
        }
      });

      controller.forward();
    }
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
        future: Future.wait([getHikeByID(widget.hikeID), getSamplesByID(widget.hikeID)]), 
        builder: (context, allData) {
            ConnManager connManager = Provider.of<ConnManager>(context, listen:false);
            bool isHikeActive = connManager.isHikeActive(widget.hikeID);

            late Map hikeData;
            if (allData.data?[0] != null) {
              hikeData = Map.from(allData.data?[0][0] as Map<Object?, Object?>); //default to inital hike map received on navigator push
            } else {
              hikeData = widget.initalHike;
            }

            List<LatLng> routeCoords = [];
            List<Map>? receivedMaps = allData.data?[1]; 
            late List<Map> samples;

            if (receivedMaps != null) {
              samples = receivedMaps;
            } else {
              samples = widget.initialMaps; //default to the initalMaps list received on navigator push
            }
            
            if (samples.isNotEmpty) {
              for (var i = 0; i < samples.length; i ++) {
                  LatLng coord = LatLng(samples[i]['lat'], samples[i]['long']);
                  routeCoords.add(coord);
                }
            }

            late LatLngBounds bounds; 

            if (routeCoords.length > 1) bounds = getRouteBounds(routeCoords);

            return SingleChildScrollView(
              child: Column(
              children: [
                isHikeActive ? ListTile(
                  leading: Icon(Icons.radio_button_checked, 
                    color: Colors.red,), 
                  title: Text('This hike is currently active'),
                  trailing: TextButton(onPressed: () {
                    connManager.deactivateHike();
                    if (routeCoords.length > 1){
                      moveMapToRouteBounds(routeCoords);
                    }
                    setState(() {
                      isHikeActive = connManager.isHikeActive(widget.hikeID);
                    });
                  }, child: Text('deactivate')),
                  ) : 
                ListTile(
                  leading: Icon(Icons.radio_button_unchecked,
                    color: Colors.grey,
                  ),
                  title: Text('This hike is not active'),
                  trailing: TextButton(onPressed: () {
                    connManager.activateHike(widget.hikeID);
                    setState(() {
                      isHikeActive = connManager.isHikeActive(widget.hikeID);
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
                      'Start Date & Time: ${hikeData['date']}',
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
                      options: routeCoords.length < 2 ? MapOptions(
                        initialCenter: LatLng(51.5, 0.127),
                        initialZoom: 9,
                      ) :
                      MapOptions(
                        initialCameraFit: CameraFit.bounds(bounds: bounds),
                      ),
                      mapController: _mapController,
                      children: isHikeActive ? [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        CurrentLocationLayer(
                          alignPositionOnUpdate: AlignOnUpdate.always,
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
                      ] : [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                              onPressed: () async {
                                List<Map> allSamples = await getSamplesByID(widget.hikeID);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => SampleDetail(hikeId: widget.hikeID, initialSamples: allSamples,)));
                              }, 
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll<Color>(Colors.grey),
                                foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                                ),
                              child: Text('View data samples >'),
                              )
                      ),
                TextButton(//TODO: remove test button and switch data receive control to conn_manager
                              onPressed: () async {
                                Position currentPosition = await Geolocator.getCurrentPosition();
                                debugPrint('$currentPosition');
                                int newSampleId = await getLatestID('samples');
                                if (connManager.getActiveHikeId != -1){
                                  setState(() {
                                    insertSample(
                                      Sample(
                                        id: newSampleId, 
                                        hikeId: widget.hikeID, 
                                        tofData: '[794, 723, 287, 269, 880, 792, 716, 206, 1001, 194, 178, 180, 1330, 1014, 181, 166, 617, 681, 734, 808, 668, 745, 797, 875, 253, 792, 859, 952, 229, 778, 857, 325, 0, 0, 100]',
                                        lat: currentPosition.latitude,
                                         long:currentPosition.longitude
                                        )
                                      );
                                  });
                                }
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
            )
            );
          }
        ),
      );
    }
}