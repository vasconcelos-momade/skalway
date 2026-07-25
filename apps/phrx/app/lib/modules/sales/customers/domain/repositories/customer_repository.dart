import '../../../../../core/contracts/pagination_response.dart';
import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<PaginationResponse<CustomerSummary>> listCustomers(CustomerQuery query);

  Future<CustomerDashboard> getDashboard();

  Future<CustomerDetail> getCustomer(String id);

  Future<CustomerDetail> createCustomer(CustomerFormPayload payload);

  Future<CustomerDetail> updateCustomer(String id, CustomerFormPayload payload);

  Future<void> deleteCustomer(String id);

  Future<PaginationResponse<CustomerFaturaRef>> listCustomerFaturas(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<PaginationResponse<CustomerContaReceber>> listCustomerContasReceber(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<PaginationResponse<CustomerReceitaRef>> listCustomerReceitas(
    String id, {
    int page = 1,
    int pageSize = 10,
  });

  Future<PaginationResponse<CustomerAuditEntry>> listCustomerAudit(
    String id, {
    int page = 1,
    int pageSize = 10,
  });
}
