    #include <Arduino.h>
    #include <HX711.h>
    #include <BluetoothSerial.h>

BluetoothSerial SerialBT;
HX711 scale;

const int HX_DT = 4;
const int HX_SCK = 5;

float calibration_factor = 7500.0;    // współczynnik kalibracji
const float zero_tolerance = 0.1;     // tolerancja ± 0.1 kg
bool isSending = false;

void setup() {
    Serial.begin(115200);
    scale.begin(HX_DT, HX_SCK);
    SerialBT.begin("WagaESP32");

    scale.set_scale(calibration_factor);
    Serial.println("Wstępne tarowanie wagi");
    scale.tare();
    Serial.println("Tarowanie zakończone.");
}

void loop() {
    if (SerialBT.available()) {
        String command = SerialBT.readString();
        command.trim();
        if (command == "START") {
            isSending = true;
        }
        else if (command == "TAROWANIE") {
            scale.tare();
            Serial.println("Waga została wytarowana.");
        }   
    }

    if (isSending) {
        if (scale.is_ready()) {
            float weight = scale.get_units(5);
            if (abs(weight) < zero_tolerance) {
                weight = 0.0;
            }
            SerialBT.println(String(weight, 2) + " kg");
            Serial.println(String(weight, 2) + " kg");
        } else {
            SerialBT.println("Oczekiwanie na HX711...");
        }
        
        delay(200);
    } 
}
