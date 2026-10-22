<?php

const BLOOD_TYPES = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

const REQUESTS_BY_BLOOD_TYPE = [
    'O+' => 82,
    'O-' => 61,
    'A+' => 74,
    'A-' => 38,
    'B+' => 53,
    'B-' => 29,
    'AB+' => 18,
    'AB-' => 12,
];

const DASHBOARD_REQUESTS = [
    ['id' => 'ACT-010', 'name' => 'Lebron James', 'blood' => 'O-', 'urgency' => 'CRITICAL', 'status' => 'Active', 'location' => 'Rosales', 'date' => '2026-09-24'],
    ['id' => 'ACT-009', 'name' => 'Donald Trump', 'blood' => 'A-', 'urgency' => 'URGENT', 'status' => 'Active', 'location' => 'Binalonan', 'date' => '2026-09-23'],
    ['id' => 'ACT-008', 'name' => 'Jessil Catilo', 'blood' => 'B+', 'urgency' => 'NORMAL', 'status' => 'Active', 'location' => 'Manila', 'date' => '2026-09-22'],
    ['id' => 'ACT-007', 'name' => 'Aurwyn Jhan Fontanilla', 'blood' => 'AB-', 'urgency' => 'CRITICAL', 'status' => 'Active', 'location' => 'La Union', 'date' => '2026-09-21'],
    ['id' => 'ACT-006', 'name' => 'Joao Baybayan', 'blood' => 'B-', 'urgency' => 'NORMAL', 'status' => 'Active', 'location' => 'Bolinao', 'date' => '2026-09-20'],
    ['id' => 'ACT-005', 'name' => 'Kobe Bryant', 'blood' => 'O+', 'urgency' => 'NORMAL', 'status' => 'Active', 'location' => 'Calasiao', 'date' => '2026-09-19'],
    ['id' => 'ACT-004', 'name' => 'James Jahamas', 'blood' => 'AB+', 'urgency' => 'URGENT', 'status' => 'Active', 'location' => 'Urdaneta City', 'date' => '2026-09-18'],
    ['id' => 'ACT-003', 'name' => 'Sherwin Acosta', 'blood' => 'B-', 'urgency' => 'CRITICAL', 'status' => 'Active', 'location' => 'Dagupan City', 'date' => '2026-09-17'],
    ['id' => 'ACT-002', 'name' => 'Jameel Luga', 'blood' => 'A+', 'urgency' => 'URGENT', 'status' => 'Active', 'location' => 'Baguio City', 'date' => '2026-09-16'],
    ['id' => 'ACT-001', 'name' => 'Bong Catilo', 'blood' => 'O-', 'urgency' => 'NORMAL', 'status' => 'Active', 'location' => 'Batangas', 'date' => '2026-09-15'],
];

const DONATIONS = [
    ['id' => 'DON-008', 'name' => 'Miguel Pajatin', 'blood' => 'O-', 'status' => 'Cancelled', 'location' => 'Urdaneta City', 'date' => '2026-08-30', 'requestId' => 'REQ-008'],
    ['id' => 'DON-007', 'name' => 'Selwyn Decenon', 'blood' => 'A-', 'status' => 'Fulfilled', 'location' => 'Baguio City', 'date' => '2026-08-30', 'requestId' => 'REQ-007'],
    ['id' => 'DON-006', 'name' => 'Romeo Lagmay', 'blood' => 'B+', 'status' => 'Fulfilled', 'location' => 'Dagupan City', 'date' => '2026-08-22', 'requestId' => 'REQ-006'],
    ['id' => 'DON-005', 'name' => 'Ja Morant', 'blood' => 'AB-', 'status' => 'Fulfilled', 'location' => 'Binalonan', 'date' => '2026-08-18', 'requestId' => 'REQ-005'],
    ['id' => 'DON-004', 'name' => 'Gabriel Go', 'blood' => 'B-', 'status' => 'Fulfilled', 'location' => 'Tarlac City', 'date' => '2026-08-13', 'requestId' => 'REQ-004'],
    ['id' => 'DON-003', 'name' => 'Micah Fontanilla', 'blood' => 'O+', 'status' => 'Fulfilled', 'location' => 'Rosales', 'date' => '2026-08-07', 'requestId' => 'REQ-003'],
    ['id' => 'DON-002', 'name' => 'Sheinne Panelo', 'blood' => 'AB+', 'status' => 'Fulfilled', 'location' => 'Villasis', 'date' => '2026-08-06', 'requestId' => 'REQ-002'],
    ['id' => 'DON-001', 'name' => 'Nathaniel Somera', 'blood' => 'B-', 'status' => 'Fulfilled', 'location' => 'Pampanga', 'date' => '2026-08-04', 'requestId' => 'REQ-001'],
];

const BLOOD_REQUESTS = [
    ['id' => 'REQ-008', 'name' => 'Jhan Winzel Fontanilla', 'blood' => 'O-', 'urgency' => 'CRITICAL', 'status' => 'Cancelled', 'location' => 'Manila', 'date' => '2026-08-29', 'donationId' => 'DON-008'],
    ['id' => 'REQ-007', 'name' => 'Bryan James Aquino', 'blood' => 'A-', 'urgency' => 'URGENT', 'status' => 'Fulfilled', 'location' => 'Urdaneta City', 'date' => '2026-08-28', 'donationId' => 'DON-007'],
    ['id' => 'REQ-006', 'name' => 'Reid Herve Tulali', 'blood' => 'B+', 'urgency' => 'NORMAL', 'status' => 'Fulfilled', 'location' => 'Baguio City', 'date' => '2026-08-20', 'donationId' => 'DON-006'],
    ['id' => 'REQ-005', 'name' => 'Jan Denver Ignacio', 'blood' => 'AB-', 'urgency' => 'CRITICAL', 'status' => 'Fulfilled', 'location' => 'Dagupan City', 'date' => '2026-08-17', 'donationId' => 'DON-005'],
    ['id' => 'REQ-004', 'name' => 'Althea Castillo', 'blood' => 'B-', 'urgency' => 'NORMAL', 'status' => 'Fulfilled', 'location' => 'Binalonan', 'date' => '2026-08-12', 'donationId' => 'DON-004'],
    ['id' => 'REQ-003', 'name' => 'Andre Fernandez', 'blood' => 'O+', 'urgency' => 'NORMAL', 'status' => 'Fulfilled', 'location' => 'Tarlac City', 'date' => '2026-08-05', 'donationId' => 'DON-003'],
    ['id' => 'REQ-002', 'name' => 'Karl Yanga', 'blood' => 'AB+', 'urgency' => 'URGENT', 'status' => 'Fulfilled', 'location' => 'Rosales', 'date' => '2026-08-04', 'donationId' => 'DON-002'],
    ['id' => 'REQ-001', 'name' => 'Weincy Tolentino', 'blood' => 'B-', 'urgency' => 'CRITICAL', 'status' => 'Fulfilled', 'location' => 'Villasis', 'date' => '2026-08-03', 'donationId' => 'DON-001'],
];

const NOTIFICATIONS = [
    ['title' => 'Critical blood request', 'body' => 'ACT-010 needs attention.', 'time' => '17 minutes ago', 'tone' => 'danger'],
    ['title' => 'Donation completed', 'body' => 'DON-007 was completed successfully.', 'time' => '9 days ago', 'tone' => 'success'],
];
