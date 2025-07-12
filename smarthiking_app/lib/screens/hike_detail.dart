import 'dart:io';

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
import 'dart:async';
import 'package:path_provider/path_provider.dart';

import 'package:vector_math/vector_math_64.dart' as vmath;

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

  @override
  void initState() {
    super.initState();
    initLocation();
    _mapController = MapController();
  }

  void initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled (from geolocator docs https://pub.dev/packages/geolocator).
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }
  }

  //Modified version of Nitesh's solution on StackOverflow (https://stackoverflow.com/questions/66181115/flutter-polyline-distance-with-google-maps-flutter-plugin)
  double calculateDistance(List<LatLng> polyline) {
    double totalDistance = 0;
    double earthRadius = 6371;
    for (int i = 0; i < polyline.length; i++) {
      if (i < polyline.length - 1) { // skip the last index
        double diffLat = vmath.radians(polyline[i + 1].latitude - polyline[i].latitude);
        double diffLong = vmath.radians(polyline[i + 1].longitude - polyline[i].longitude);

        double lat1 = vmath.radians(polyline[i].latitude);
        double lat2 = vmath.radians(polyline[i + 1].latitude);

        double a = sin(diffLat / 2) * sin(diffLat / 2) + cos(lat1) * cos(lat2) * sin(diffLong / 2) * sin(diffLong / 2); 
        double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      
        totalDistance += earthRadius * c;
      }
    }
    debugPrint('$totalDistance');
    return totalDistance;
  }

  dynamic getRouteBounds (List<LatLng> routeCoords) {
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

    if (Point(startCoord.latitude, startCoord.longitude).distanceTo(Point(endCoord.latitude, endCoord.longitude)) > 0) {
        LatLngBounds bounds = LatLngBounds(startCoord, endCoord);
        return bounds;
    } else {
      return -1;
    }
  }

  //derived from animated_map_controller by JaffaKetchup on GitHub
  void moveMapToRouteBounds (List<LatLng> routeCoords) {
      dynamic bounds = getRouteBounds(routeCoords);

      if (bounds != -1) {
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

  Future<void> _handleRefresh() async {
    // Simulate network fetch or database query
    await Future.delayed(Duration(seconds: 2));
    // Update the list of items and refresh the UI
    setState(() {});
  }

  Future<File> _getLocalFile(String filename) async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    return file;
  }

  @override
  Widget build(BuildContext context) {
    ConnManager connManager = Provider.of<ConnManager>(context, listen:true);
    
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
      body: RefreshIndicator(
        onRefresh: _handleRefresh, // from https://www.dhiwise.com/post/flutter-pull-to-refresh-how-to-implement-customize
        child: FutureBuilder(
          future: Future.wait([getHikeByID(widget.hikeID), getSamplesByID(widget.hikeID)]), //TODO: add future _getLocalFile("flutter_assets/image.png")
          builder: (context, allData) {
              bool isHikeActive = connManager.isHikeActive(widget.hikeID);

              //List<List<Map<dynamic, dynamic>>> _allData = List.from(allData.data as List<List<Map<dynamic, dynamic>>>);

              late Map hikeData;
              if (allData.data?[0] != null) {
                hikeData = Map.from(allData.data?[0][0] as Map<Object?, Object?>); //default to inital hike map received on navigator push
              } else {
                hikeData = widget.initalHike;
              }

              List<LatLng> routeCoords = [];
              List<double> elevations = [];
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
                    elevations.add(samples[i]['elevation']);
                  }
                elevations.sort();
              }

              late dynamic bounds; 

              if (routeCoords.length > 1) {
                bounds = getRouteBounds(routeCoords);
              } else {
                bounds = -1;
              }

              Polyline trace = Polyline(
                              points: routeCoords,
                              color: Colors.blue,
                              strokeWidth: 5,
                              );
              
              double traceDist = calculateDistance(routeCoords);

              return SingleChildScrollView(
                child: Column(
                children: [
                  isHikeActive ? ListTile(
                    leading: Icon(Icons.radio_button_checked, 
                      color: Colors.red,), 
                    title: Text('This hike is currently active'),
                    trailing: TextButton(onPressed: () {
                      connManager.deactivateHike();
                      if (routeCoords.length > 1) {
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
                        options: (routeCoords.length < 2 || bounds == -1) ? MapOptions(
                          initialCenter: LatLng(51.5, 0.127),
                          initialZoom: 12,
                        ) :
                        MapOptions(
                          initialCameraFit: CameraFit.bounds(bounds: bounds),
                        ),
                        mapController: _mapController,
                        children: isHikeActive ? [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'dev.terranger',
                            tileProvider: NetworkTileProvider(
                              cachingProvider:BuiltInMapCachingProvider.getOrCreateInstance()
                            )
                          ),
                          CurrentLocationLayer(
                            alignPositionOnUpdate: AlignOnUpdate.always,
                          ),
                          PolylineLayer(
                            polylines: routeCoords.isNotEmpty ? [trace] :
                            <Polyline<Object>> []),
                          RichAttributionWidget(attributions: [
                            TextSourceAttribution('OpenStreetMap contributors')
                          ])
                        ] : [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'dev.terranger',
                            tileProvider: NetworkTileProvider(
                              cachingProvider:BuiltInMapCachingProvider.getOrCreateInstance()
                            )
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
                  //ConstrainedBox(
                  //  constraints: const BoxConstraints(maxHeight: 100),
                  //  child: CarouselView(
                   //   scrollDirection: Axis.horizontal,
                   //   shrinkExtent: 50,
                    //  shape: ContinuousRectangleBorder(),
                   //   itemExtent: 150,
                    //  children: List<Widget>.generate(5, (int index) {
                    //    return Center(
                     //     child: Container(
                      //      width: MediaQuery.of(context).size.width / 3,
                      //      height: 100,
                      //      decoration: BoxDecoration(
                       //       color: Colors.amber
                         //   ),
                       //     child: Text('text $index', style: TextStyle(fontSize: 16.0),)
                        //  ),
                      //  );
                    //  }),
                   // ),
                //  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(15, 10, 15, 5),
                        child: Column(
                            children: [
                              Icon(Icons.route),
                              Text('Distance'),
                              Text('${traceDist.toStringAsFixed(2)} km',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                  ),
                              )
                            ],
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(15, 10, 15, 5),
                        child: Column(
                          children: [
                            Icon(Icons.terrain),
                            Text('Max Elevation'),
                            Text('${elevations.isNotEmpty ? elevations.last.toStringAsFixed(2) : 0} ft',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                  ),
                              )
                          ],
                        )
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(15, 10, 15, 5),
                        child: Column(
                          children: [
                            Icon(Icons.timeline),
                            Text('Data samples'),
                            Text('${samples.length}', // TODO: Add sample count from db sample table
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
                      Padding(padding: EdgeInsets.fromLTRB(20, 10, 20, 40),
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
                    ],
                  ),
                  
                ],
              )
              );
            }
          ),
        )
      );
    }
}