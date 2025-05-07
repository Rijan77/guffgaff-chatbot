import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final helloProvider = Provider<String>((ref){
  return ("What can I help with?");
});

// final iconprovider = Provider((ref){
//   return Icon(Icons.settings, size: 40, color: Colors.white,);
// });

class Myhomepage extends ConsumerStatefulWidget{
  const Myhomepage({super.key});

  @override
  ConsumerState<Myhomepage> createState() => _MyhomepageState();
}

class _MyhomepageState extends ConsumerState<Myhomepage> {
  @override
  Widget build(BuildContext context) {
    final hello = ref.watch(helloProvider);
    // final icon = ref.watch(iconprovider);
    return Scaffold(
      backgroundColor: const Color(0xff1E1E1E),
      body: SingleChildScrollView(
        child: Column(
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
                  const Padding(
                    padding: EdgeInsets.only(left: 100, top: 40),
                    child: Text("GuffGaff", style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500
                    ),),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 100, top: 30),
                    child: Icon(Icons.settings, color: Colors.white, size: 35,)
                  )
                ],
              ),
            const SizedBox(height: 300,),

            Text(hello, style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
            ),),

        const SizedBox(height: 290,),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 130,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
              ),

              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Ask any things",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,

                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10,),
                      const Icon(Icons.send, color: Colors.white)
                    ],

                  ),

                    const Padding(
                      padding: EdgeInsets.only(top: 27, left: 15),
                      child: Row(
                        children: [
                          Icon(Icons.photo, color: Colors.grey, size: 27,),

                          SizedBox(width: 15,),

                          Icon(Icons.camera_alt, color: Colors.grey, size: 27,)
                        ],
                      ),
                    ),
                ],
              ),

            )

          ],
        ),
      ),
    );
  }
}
