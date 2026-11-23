import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../providers/auth_provider.dart';

Dio workspaceApi(BuildContext context) =>
    context.read<AuthProvider>().client.dio;

String friendlyLabel(String value) => value
    .replaceAll('_', ' ')
    .replaceAll('-', ' ')
    .split(' ')
    .map((word) => word.isEmpty
        ? ''
        : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
    .join(' ');

const claimStatuses = [
  'UPLOADED',
  'PROCESSING',
  'REVIEW_REQUIRED',
  'INFORMATION_REQUIRED',
  'INFORMATION_RECEIVED',
  'VERIFIED',
  'APPROVED',
  'REJECTED',
  'PAYMENT_PENDING',
  'PAID',
  'PROCESSING_FAILED'
];
const accountRoles = [
  'client',
  'claims_officer',
  'supervisor',
  'administrator'
];
