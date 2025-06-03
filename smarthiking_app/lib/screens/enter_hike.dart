import 'package:flutter/material.dart';
import 'package:smarthiking_app/models/conn_manager.dart';
import 'package:smarthiking_app/models/db_manager.dart';
import 'package:smarthiking_app/screens/hike_detail.dart';
import 'package:provider/provider.dart';

class EnterHike extends StatefulWidget {
  const EnterHike({super.key});

  @override
  State<EnterHike> createState() => _EnterHikeState();
}

class _EnterHikeState extends State<EnterHike> {
  @override
  Widget build(BuildContext context) {
    ConnManager connManager = Provider.of<ConnManager>(context, listen:false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Enter New Hike'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('What should we call this journey?'),
            Padding(
              padding: EdgeInsets.fromLTRB(50, 20, 50, 20),
              child: TextField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter a name',
                        ),
                        onSubmitted: (value) async {
                          //Create new db entry on submit and navigator push to trip data screen
                          int newId = await getLatestID('hikes');
                          debugPrint('$newId');
                          String date = DateTime.now().toString();
                          Hike newHike = Hike(id:newId, name:value, date: date);
                          insertHike(newHike);
                          connManager.activateHike(newId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HikeDetail(hikeID: newId, initalHike: newHike.toMap(), initialMaps: []))
                          );
                        },
                      )
            ),
          ],
        ),
      ),
    );
  }
} 