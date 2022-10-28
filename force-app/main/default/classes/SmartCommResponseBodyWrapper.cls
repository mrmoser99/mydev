/**
* Name: SmartCommResponseBodyWrapper 
* Purpose: Class creates the JSON response of the SmartComm API.
* Version 1.0 @author Neha Bansal @date 2021-07-28
*/
public class SmartCommResponseBodyWrapper extends BaseResponseBodyWrapper {
    
	public List<Envelopes> envelopes;
	public Object previewKey;
	public Integer numberTransactions;
	public List<SlaveChannels> exceptions;
	public Object dataModelValuesLocation;
	public List<JobMessages> jobMessages;
    
    public class Envelopes {
		public MasterChannel masterChannel;
		public List<SlaveChannels> slaveChannels;
	}

	public class MasterChannel {
		public Integer pageCount;
		public Integer channelType;
		public String channelName;
		public String data;
		public List<Properties> properties;
		public String documentName;
		public String mimeType;
		public Integer channelId;
	}

	public class SlaveChannels {
        
        public Integer pageCount;
		public Integer channelType;
		public String channelName;
		public List<Properties> properties;
        public String documentName;
		public String mimeType;
		public Integer channelId;
        
	}

	public class Properties {
		public String name;
		public String value;
	}

	public class JobMessages {
		public Integer docID;
		public String msgType;
		public String msgText;
		public String msgDate;
		public List<String> args;
		public Integer msgID;
		public Integer transactionNo;
		public Integer destID;
		public Integer channelID;
		public Integer packageID;
		public Integer batchID;
	}

	
	    
    public override BaseResponseBodyWrapper deserialize(String className, String responseString) {
        String responseBody = responseString.removeStart('while(1);');
        return (BaseResponseBodyWrapper) super.deserialize(className, responseBody);
        
    }

}