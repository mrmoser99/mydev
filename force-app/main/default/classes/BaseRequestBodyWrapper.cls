/**
 * This class is used in RESTCallout service class to create callout and set params. 
 * It is extended to provide request body wrapper for each callout
 * 
 * @author Elena Sokolova @date 2021-01-15
 */
public abstract class BaseRequestBodyWrapper {

    /**
     * Method sets class variables.
     * Because it is declared virtual it can be overridden by a subclass
     */
    public virtual void init(Map<String, Object> params) {}

    /**
     * Method serializes current instance of the class.
     * Because it is declared virtual it can be overridden by a subclass.
     * 
     * @return request body as JSON string
     */
    public virtual String getRequestBodyAsString() {
        return JSON.serialize(this, true);
    }
}