/**
 * This class is used in RESTCallout service class to create callout and set params. 
 * It provide request body wrapper for Cancel Order callout
 * 
 * @author Elena Sokolova @date 2021-06-22
 */
public with sharing class CancelOrderRequestBodyWrapper extends BaseRequestBodyWrapper {
    public String OrderId;

    public CancelOrderRequestBodyWrapper() {}

    /**
     * Method sets class variables.
     * Override the parent class method with this signature.
     */
    public override void init(Map<String, Object> params) {

        super.init(params);

        this.OrderId = (String) params.get('orderId');
    }
}