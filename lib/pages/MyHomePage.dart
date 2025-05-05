import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final helloProvider = Provider<String>((ref){
  return ("What can I help with?");
});

class Myhomepage extends ConsumerStatefulWidget{
  const Myhomepage({super.key});

  @override
  ConsumerState<Myhomepage> createState() => _MyhomepageState();
}

class _MyhomepageState extends ConsumerState<Myhomepage> {
  @override
  Widget build(BuildContext context) {
    final hello = ref.watch(helloProvider);
    return Scaffold(
      backgroundColor: const Color(0xff1E1E1E),
      body: Column(
        children: [
          Row(
              children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 30, left: 10),
                      child: Image.asset(
                        "lib/assets/Logo.png", width: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                Padding(
                  padding: const EdgeInsets.only(left: 100, top: 40),
                  child: Text("GuffGaff", style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500
                  ),),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 100, top: 30),
                  child: Icon(Icons.settings, color: Colors.white, size: 35,),
                )
              ],
            ),

        ],
      ),
    );
  }
}
