import 'package:flutter/material.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1F4CCF);
    const Color lightBlueText = Color(0xFF8FA3DD);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // Title
              const Text(
                "ICC ProcuraX",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 22),

              // ICC Logo Image from assets
              Expanded(
  child: Center(
    child: Image.asset(
      "assets/icc_logo.png",
      width: MediaQuery.of(context).size.width * 0.9,
      fit: BoxFit.contain,
    ),
  ),
),


              const SizedBox(height: 60),

              // Construction Meets Control
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Construction",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD0D6EA), // greyish
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Meets",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: lightBlueText,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Control",
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "/procurement");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8EEFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Footer
              const Text(
                "@2024 ICC ProcuraX. All rights reserved.",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
