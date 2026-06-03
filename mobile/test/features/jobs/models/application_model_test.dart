import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/jobs/models/application_model.dart';

void main() {
  group('CandidateModel', () {
    group('fromJson', () {
      test('creates CandidateModel from complete JSON', () {
        final json = <String, dynamic>{
          'id': '1',
          'name': 'John Doe',
          'email': 'john@example.com',
        };

        final candidate = CandidateModel.fromJson(json);

        expect(candidate.id, '1');
        expect(candidate.name, 'John Doe');
        expect(candidate.email, 'john@example.com');
      });

      test('defaults to empty strings when fields missing', () {
        final json = <String, dynamic>{};

        final candidate = CandidateModel.fromJson(json);

        expect(candidate.id, '');
        expect(candidate.name, '');
        expect(candidate.email, '');
      });

      test('handles partial JSON', () {
        final json = <String, dynamic>{
          'id': '2',
          'name': 'Jane Smith',
        };

        final candidate = CandidateModel.fromJson(json);

        expect(candidate.id, '2');
        expect(candidate.name, 'Jane Smith');
        expect(candidate.email, '');
      });
    });

    group('Constructor', () {
      test('creates CandidateModel with all fields', () {
        final candidate = CandidateModel(
          id: '1',
          name: 'John Doe',
          email: 'john@example.com',
        );

        expect(candidate.id, '1');
        expect(candidate.name, 'John Doe');
        expect(candidate.email, 'john@example.com');
      });
    });
  });

  group('ApplicationModel', () {
    group('fromJson', () {
      test('creates ApplicationModel from complete JSON', () {
        final json = <String, dynamic>{
          'id': 'app1',
          'jobId': 'job1',
          'candidateId': 'cand1',
          'coverLetter': 'I am interested in this role',
          'status': 'ACCEPTED',
          'appliedAt': '2025-06-01T10:30:00Z',
          'resumeFileName': 'resume.pdf',
          'candidate': {
            'id': 'cand1',
            'name': 'John Doe',
            'email': 'john@example.com',
          },
        };

        final app = ApplicationModel.fromJson(json);

        expect(app.id, 'app1');
        expect(app.jobId, 'job1');
        expect(app.candidateId, 'cand1');
        expect(app.coverLetter, 'I am interested in this role');
        expect(app.status, 'ACCEPTED');
        expect(app.appliedAt, '2025-06-01T10:30:00Z');
        expect(app.resumeFileName, 'resume.pdf');
        expect(app.candidate.name, 'John Doe');
      });

      test('defaults to PENDING status when missing', () {
        final json = <String, dynamic>{
          'id': 'app2',
          'jobId': 'job2',
          'candidateId': 'cand2',
          'appliedAt': '2025-06-01T10:30:00Z',
          'candidate': <String, dynamic>{},
        };

        final app = ApplicationModel.fromJson(json);

        expect(app.status, 'PENDING');
      });

      test('handles nullable coverLetter', () {
        final json = <String, dynamic>{
          'id': 'app3',
          'jobId': 'job3',
          'candidateId': 'cand3',
          'status': 'PENDING',
          'appliedAt': '2025-06-01T10:30:00Z',
          'candidate': <String, dynamic>{},
        };

        final app = ApplicationModel.fromJson(json);

        expect(app.coverLetter, isNull);
      });

      test('handles nullable resumeFileName', () {
        final json = <String, dynamic>{
          'id': 'app4',
          'jobId': 'job4',
          'candidateId': 'cand4',
          'status': 'REJECTED',
          'appliedAt': '2025-06-01T10:30:00Z',
          'candidate': <String, dynamic>{},
        };

        final app = ApplicationModel.fromJson(json);

        expect(app.resumeFileName, isNull);
      });

      test('defaults to empty strings when required fields missing', () {
        final json = <String, dynamic>{
          'candidate': <String, dynamic>{},
        };

        final app = ApplicationModel.fromJson(json);

        expect(app.id, '');
        expect(app.jobId, '');
        expect(app.candidateId, '');
        expect(app.appliedAt, '');
      });

      test('creates nested CandidateModel correctly', () {
        final json = <String, dynamic>{
          'id': 'app5',
          'jobId': 'job5',
          'candidateId': 'cand5',
          'status': 'PENDING',
          'appliedAt': '2025-06-01T10:30:00Z',
          'candidate': {
            'id': 'cand5',
            'name': 'Alice Wonder',
            'email': 'alice@example.com',
          },
        };

        final app = ApplicationModel.fromJson(json);

        expect(app.candidate.id, 'cand5');
        expect(app.candidate.name, 'Alice Wonder');
        expect(app.candidate.email, 'alice@example.com');
      });
    });

    group('Constructor', () {
      test('creates ApplicationModel with all fields', () {
        final candidate = CandidateModel(
          id: 'cand1',
          name: 'John Doe',
          email: 'john@example.com',
        );

        final app = ApplicationModel(
          id: 'app1',
          jobId: 'job1',
          candidateId: 'cand1',
          coverLetter: 'I am interested',
          status: 'ACCEPTED',
          appliedAt: '2025-06-01',
          candidate: candidate,
          resumeFileName: 'resume.pdf',
        );

        expect(app.id, 'app1');
        expect(app.jobId, 'job1');
        expect(app.candidate.name, 'John Doe');
      });

      test('allows nullable coverLetter and resumeFileName', () {
        final candidate = CandidateModel(
          id: 'cand2',
          name: 'Jane Smith',
          email: 'jane@example.com',
        );

        final app = ApplicationModel(
          id: 'app2',
          jobId: 'job2',
          candidateId: 'cand2',
          status: 'PENDING',
          appliedAt: '2025-06-01',
          candidate: candidate,
        );

        expect(app.coverLetter, isNull);
        expect(app.resumeFileName, isNull);
      });
    });
  });
}
