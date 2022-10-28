@isTest
public class PushCommentsInfoleaseTestClass {
    
    @isTest static void pushComments_M1(){
        PushCommentsInfolease.pushcommentsWrapper wrap = new PushCommentsInfolease.pushcommentsWrapper();
        wrap.commentbody = 'TestClass for PushComments';
        wrap.contractId = '001-0000080-000';
        wrap.departmentName = 'Collections';
        wrap.emailId = 'abc@gmail.com';
   
    
    Test.setMock(HttpCalloutMock.class, new Infolease_AccessTokenMockCallout());
    Test.setMock(HttpCalloutMock.class, new PushCommentsGenerateResponseMockCallout());
        List<PushCommentsInfolease.pushcommentsWrapper> wrapList = new  List<PushCommentsInfolease.pushcommentsWrapper>();
        wrapList.add(wrap);
        Test.startTest();
        PushCommentsInfolease.sendComments(wrapList);
        Test.stopTest();
}
     }