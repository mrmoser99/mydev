@isTest
public class ContractListViewTest {
    @isTest static  void method1() {        
        //query all opportunities
        List<Contract__c> contractList = ContractListView.getRecords('00178000007ZzA6AAK', 5, 0);
        Integer totalNum1 = ContractListView.getTotalRecords('00178000007ZzA6AAK');
        system.debug('AccountApplications==>'+contractList.size());
        system.debug('totalNum1==>'+totalNum1);
    }
}