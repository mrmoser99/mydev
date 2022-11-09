public class JSONGetDocument{

    public class GetDocument {
        public String din;
        public Long timeStamp;
        public Integer maxObjSize;
    }

    public GetDocument getDocument;

    
    public static JSONGetDocument parse(String json) {
        return (JSONGetDocument) System.JSON.deserialize(json, JSONGetDocument.class);
    }
}