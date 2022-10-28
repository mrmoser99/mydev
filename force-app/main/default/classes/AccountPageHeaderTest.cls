@isTest
public class AccountPageHeaderTest {
    
    @isTest static  void method1() {

        Account at =new Account();
        at.Name='Service';
        insert at;
        AccountPageHeader.getAccountData(at.id);
        try {
            AccountPageHeader.createNewOppForCreditCheck('');
            AccountPageHeader.createNewOppForCreditCheck(at.id);
        } catch (Exception e) {
            System.debug('Exception Thrown');
        }
        
        //query all opportunities
        List<Opportunity> oppList1 = AccountPageHeader.getRecords('00178000007ZzA6AAK', 5, 0);
        Integer totalNum1 = AccountPageHeader.getTotalRecords('00178000007ZzA6AAK');
        system.debug('AccountApplications==>'+oppList1.size());                
    }
}