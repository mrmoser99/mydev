/********************************************************************
 * Change Log:
 *
 * 09/27/2022 - MRM Create Test Class
 *
 *********************************************************************/
@isTest
public class TestFileUploader {


Static testmethod void test1() {

	Account a = new Account(name = 'mark');
	insert a;

	String base64;
	base64 = EncodingUtil.Base64Encode(Blob.valueOf('test'));
	String fileName = 'test.pdf';
	String recordId = a.id;


	FileUploader.uploadFile(base64, filename, recordId);

}
}