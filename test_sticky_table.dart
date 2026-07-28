import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: Scaffold(body: MyTable())));

class MyTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(height: 50, color: Colors.blue, child: Text('Toolbar')),
        // Table Area
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1000,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(height: 50, color: Colors.red, child: Text('Header')),
                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: List.generate(50, (i) => Container(
                          height: 50,
                          color: i.isEven ? Colors.grey[200] : Colors.white,
                          child: Text('Row $i'),
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Pagination
        Container(height: 50, color: Colors.green, child: Text('Pagination')),
      ],
    );
  }
}
