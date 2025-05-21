import 'package:flutter/material.dart';
class EnterHike extends StatefulWidget {
  const EnterHike({super.key});

  @override
  State<EnterHike> createState() => _EnterHikeState();
}

class _EnterHikeState extends State<EnterHike> {
  @override
  Widget build(BuildContext context) {
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
                        onChanged: (value) => 0, //TODO: create var and store new input on changed
                        onSubmitted: (value) {
                          //TODO: create new db entry on submit and navigator push to trip data screen
                        },
                      )
            ),
          ],
        ),
      ),
    );
  }
} 