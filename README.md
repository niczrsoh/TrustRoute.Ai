# TrustRoute.Ai

TrustRoute.Ai is a next-generation logistics and supply chain management platform designed to provide end-to-end visibility, automated defect detection, and cryptographic security for global shipments.

## Key Features

1. **AI-Driven Defect Detection**
   - Automatically analyze cargo conditions using AI. Personnel can capture images of shipments at various checkpoints, and the AI models immediately evaluate and report damages or anomalies.
   
2. **Global Real-Time Monitoring**
   - Track massive shipping fleets across international waters in real-time (e.g., Japan → Thailand → Malaysia).
   - Visualize real-time location data, routes, and ETA on an interactive global map interface.

3. **Blockchain Evidence Trail**
   - Implements immutable, tamper-proof record-keeping using Ethereum Smart Contracts.
   - Every shipment event (Origin dispatch, transit checks, damage reports, destination arrival) is hashed and stored on the Sepolia Testnet as cryptographic evidence. 
   - Eliminates disputes between logistics partners regarding *when* and *where* a defect occurred.

4. **Automated Emergency Alerts**
   - The system instantly triggers location-aware alerts when defects are reported or transit conditions fall out of compliance, ensuring rapid intervention.

5. **Comprehensive Analytics Dashboard**
   - Detailed history, filtering, sorting, and analytics of all reported defects across the entire supply chain.

## Repository Structure

This repository is structured as a monorepo containing:

- `/mobile_app` - The Flutter mobile application for personnel and supply chain managers.
- `/backend` - The server-side infrastructure and APIs.
- `/arduino` - IoT hardware integrations for real-time telemetry (e.g., container temperature and humidity sensors).

## Getting Started (Mobile App)

To run the Flutter mobile application:
```bash
cd mobile_app
flutter pub get
flutter run
```
