import 'package:flutter/material.dart';
import 'package:smarthiking_app/models/conn_manager.dart';
import 'package:smarthiking_app/widgets/bottom_navbar.dart';
import 'package:smarthiking_app/screens/enter_hike.dart';
import 'package:smarthiking_app/screens/hike_detail.dart';
import 'package:smarthiking_app/models/db_manager.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    ConnManager connManager = Provider.of<ConnManager>(context, listen:false);

    Future<void> showDeleteDialog(int index, String hikeName) async {
      String confirmName = '';
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Warning!'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('This action cannot be undone. Are you sure you wish to proceed with deleting this hike and all associated data?'),
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Type '$hikeName' to confirm",
                              ),
                              onChanged: (value) => confirmName = value,
                              )
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  if (confirmName == hikeName) {
                    if (connManager.getActiveHikeId == index) {
                      connManager.deactivateHike();
                    }
                    setState(() {
                      deleteHike(index);
                      deleteAllSamples(index);
                    });
                    Navigator.of(context).pop();
                  } else {
                    debugPrint('$confirmName, $hikeName');
                  }
                },
                style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(Colors.redAccent),
                    foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                    ),
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(Colors.grey),
                    foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                    ),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
      body: Center(child: FutureBuilder(
        future: getAllData('hikes'),
        builder: (context, hikeMap) {
          late List<Map> hikeData;
          if (hikeMap.data != null){
            hikeData = List.from(hikeMap.data as List<Map>);
          } else {
            hikeData = [];
          }

          if (hikeData.isNotEmpty) {
            return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: hikeMap.data?.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child:Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.hiking),
                          title: Text(
                            hikeMap.data?[index]['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18.0,
                            ),
                            ),
                          subtitle: Text('Date: ${hikeMap.data?[index]['date']}'),
                          trailing: PopupMenuButton<int>(
                            onSelected: (int selected) {
                              switch (selected) {
                                case 0:
                                  debugPrint('${hikeMap.data?[index]['id']}');
                                  showDeleteDialog(hikeMap.data?[index]['id'], hikeMap.data?[index]['name']); 
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                              const PopupMenuItem(value: 0, child: Text('Delete this hike'))
                            ],
                            icon: Icon(Icons.more_vert)),
                        ),
                        SizedBox(
                          //height: 300, TODO: add some content
                        ),
                        ListTile(
                          leading: Icon(Icons.route),
                          title: Text('0 km travelled'), //TODO: add getter func for distance from polyline
                        ),ListTile(
                          leading: Icon(Icons.terrain),
                          title: Text('Max elevation 0 ft'), //TODO: add getter func for max elevation from samples
                        ),
                        TextButton(onPressed: ()async {
                          List<Map> initialMaps = await getSamplesByID(hikeMap.data?[index]['id']);
                          List<Map> listedHike = await getHikeByID(hikeMap.data?[index]['id']);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HikeDetail(
                              hikeID: hikeMap.data?[index]['id'],
                              initalHike: listedHike[0],
                              initialMaps: initialMaps,
                              )
                            )
                          );
                        }, child: Text('See details >'))
                      ],
                    )
                  );
                },
              );
          } else {
            return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('No hikes logged yet'),
                ],
              );
            }
          }
        )
      )
    );
  }
} 