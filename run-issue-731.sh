#!/bin/bash
# Autonomous fix for issue #731

cd ~/sourcecontrol/AI/claude-docker-sandbox

./claude-pod.sh -m ~/sourcecontrol/AI/a2aproject/a2a-java claude \
"Fix GitHub issue #731: Add google.rpc.ErrorInfo to gRPC error responses.

BACKGROUND:
You are working on the a2a-java project which implements the A2A protocol.
Current branch: issue-731-grpc-errorinfo

TASK:
gRPC errors from the SUT do not include google.rpc.ErrorInfo in status details.
This is required by the A2A specification (section 10.6) for all A2A-specific errors.

REQUIREMENTS:
1. When A2A-specific errors are returned (e.g., TaskNotFoundError), the gRPC response MUST include:
   - google.rpc.Status with google.rpc.ErrorInfo in the details array
   - Encoded in grpc-status-details-bin trailing metadata

2. ErrorInfo fields:
   - reason: Error type in UPPER_SNAKE_CASE without 'Error' suffix (e.g., TASK_NOT_FOUND)
   - domain: Set to 'a2a-protocol.org'
   - metadata: Optional map of additional error context

3. This affects all A2A error types (TaskNotFoundError, InvalidRequestError, etc.)

VALIDATION:
- Run the TCK tests mentioned in the issue:
  * tests/compatibility/core_operations/test_error_handling.py::TestGrpcErrorStructure::test_grpc_error_for_nonexistent_task
  * tests/compatibility/grpc/test_status_codes.py::TestGrpcErrorInfo::test_error_info_in_status_details
- Ensure all existing tests still pass
- Use grpcurl to manually verify ErrorInfo appears in responses

STEPS:
1. Understand the current error handling implementation
2. Add google.rpc.ErrorInfo to A2A error responses
3. Ensure proper encoding in grpc-status-details-bin
4. Run tests to validate
5. Commit changes with clear message referencing issue #731

Work systematically and test thoroughly. The project uses Quarkus/gRPC." auto

echo ""
echo "=========================================="
echo "✅ Claude has finished working on issue #731"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  cd ~/sourcecontrol/AI/a2aproject/a2a-java"
echo "  git status"
echo "  git log"
echo "  git diff main"
echo ""
