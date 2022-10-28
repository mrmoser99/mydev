/**
 * This class is used in RESTCallout service class to handle callout response. 
 * It provides response body wrapper for Create Order callout
 * 
 * @author Elena Sokolova @date 2021-06-22
 */
public with sharing class CreateOrderResponseBodyWrapper extends BaseResponseBodyWrapper {
    public Item Item;

    public CreateOrderResponseBodyWrapper() {}

    public class SigningProcessResult {
        public String SignURL;
    }

    public class SigningProcessResults {
        public List<SigningProcessResult> SigningProcessResult;
    }

    public class Item {
        public SigningProcessResults SigningProcessResults;
    }

}