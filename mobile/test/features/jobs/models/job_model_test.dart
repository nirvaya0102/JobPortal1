import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/jobs/models/job_model.dart';

void main() {
  group('JobModel', () {
    group('fromJson', () {
      test('creates JobModel from complete JSON', () {
        final json = {
          'id': '1',
          'title': 'Flutter Developer',
          'companyName': 'Tech Corp',
          'companyLogo': 'https://example.com/logo.png',
          'location': 'Kathmandu',
          'salary': '50000-80000',
          'type': 'Full-time',
          'description': 'Join our team',
          'status': 'active',
          'applicantsCount': 5,
        };

        final job = JobModel.fromJson(json);

        expect(job.id, '1');
        expect(job.title, 'Flutter Developer');
        expect(job.companyName, 'Tech Corp');
        expect(job.companyLogo, 'https://example.com/logo.png');
        expect(job.location, 'Kathmandu');
        expect(job.salary, '50000-80000');
        expect(job.type, 'Full-time');
        expect(job.description, 'Join our team');
        expect(job.status, 'active');
        expect(job.applicantsCount, 5);
      });

      test('creates JobModel from JSON with company object', () {
        final json = {
          'id': '2',
          'title': 'Backend Developer',
          'company': {
            'name': 'StartUp Inc',
            'logo': 'https://example.com/startup.png',
          },
          'location': 'Pokhara',
          'status': 'active',
          'applicantsCount': '10',
        };

        final job = JobModel.fromJson(json);

        expect(job.id, '2');
        expect(job.title, 'Backend Developer');
        expect(job.companyName, 'StartUp Inc');
        expect(job.companyLogo, 'https://example.com/startup.png');
        expect(job.location, 'Pokhara');
        expect(job.applicantsCount, 10);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': '3',
          'title': 'UI Designer',
          'status': 'active',
          'applicantsCount': 0,
        };

        final job = JobModel.fromJson(json);

        expect(job.id, '3');
        expect(job.title, 'UI Designer');
        expect(job.companyName, isNull);
        expect(job.location, isNull);
        expect(job.salary, isNull);
        expect(job.applicantsCount, 0);
      });

      test('defaults title to "Untitled Job" when missing', () {
        final json = {
          'id': '4',
          'status': 'active',
          'applicantsCount': 0,
        };

        final job = JobModel.fromJson(json);

        expect(job.title, 'Untitled Job');
      });

      test('handles applicantsCount as string', () {
        final json = {
          'id': '5',
          'title': 'Data Scientist',
          'status': 'active',
          'applicantsCount': '15',
        };

        final job = JobModel.fromJson(json);

        expect(job.applicantsCount, 15);
      });

      test('handles _count structure for applicantsCount', () {
        final json = {
          'id': '6',
          'title': 'Product Manager',
          'status': 'active',
          '_count': {
            'applications': '20',
          },
        };

        final job = JobModel.fromJson(json);

        expect(job.applicantsCount, 20);
      });

      test('defaults applicantsCount to 0 when invalid', () {
        final json = {
          'id': '7',
          'title': 'QA Engineer',
          'status': 'active',
          'applicantsCount': 'invalid',
        };

        final job = JobModel.fromJson(json);

        expect(job.applicantsCount, 0);
      });

      test('defaults status to empty string when missing', () {
        final json = {
          'id': '8',
          'title': 'DevOps Engineer',
          'applicantsCount': 0,
        };

        final job = JobModel.fromJson(json);

        expect(job.status, '');
      });

      test('converts numeric id to string', () {
        final json = {
          'id': 123,
          'title': 'Senior Developer',
          'status': 'active',
          'applicantsCount': 0,
        };

        final job = JobModel.fromJson(json);

        expect(job.id, '123');
      });
    });

    group('Constructor', () {
      test('creates JobModel with all fields', () {
        final job = JobModel(
          id: '1',
          title: 'Test Job',
          companyName: 'Test Company',
          companyLogo: 'logo.png',
          location: 'Test Location',
          salary: '50000',
          type: 'Full-time',
          description: 'Test description',
          status: 'active',
          applicantsCount: 5,
        );

        expect(job.id, '1');
        expect(job.title, 'Test Job');
        expect(job.companyName, 'Test Company');
        expect(job.applicantsCount, 5);
      });

      test('allows nullable optional fields', () {
        final job = JobModel(
          id: '1',
          title: 'Test Job',
          status: 'active',
          applicantsCount: 0,
        );

        expect(job.companyName, isNull);
        expect(job.location, isNull);
        expect(job.salary, isNull);
      });
    });
  });
}
