import Time "mo:base/Time";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";

actor {
  public type Message = {
    text: Text;
    time: Time.Time;
  };
  
  public type Microblog = actor {
    follow: shared(Principal) -> async ();            ///添加关注对象
    follows:shared query () -> async [Principal];     ///返回关注对象
    post: shared (Text) -> async ();                  ///发布新消息
    posts : shared query (Time.Time) -> async [Message];       ///返回所有发布的消息
    timeline : shared (Time.Time) -> async [Message];          ///返回所有关注对象发布的消息
  };
  var followed : List.List<Principal> = List.nil();

  public shared func follow(id: Principal):async () {
    followed := List.push(id,followed);
  };
  public shared query func follows() : async [Principal]{
    List.toArray(followed)
  };

  var messages : List.List<Message> = List.nil();
  
  public shared (msg) func post(text: Text): async() {
  let newMessage = {
    text = text;
    time = Time.now();
  };
  messages := List.push(newMessage, messages);
  };

  public shared query func posts(since: Time.Time): async [Message] {
    let filteredMessages = List.filter(messages, func(m: Message): Bool {
        m.time >= since
    });
    List.toArray(filteredMessages)
  };

  public shared func timeline(since: Time.Time): async [Message] {
    var all: List.List<Message> = List.nil();
    
    for (id in Iter.fromList(followed)) {
        let canister: Microblog = actor(Principal.toText(id));
        let msgs = await canister.posts(since);
        for (msg in Iter.fromArray(msgs)) {
            all := List.push(msg, all);
        }
    };
    let filteredMessages = List.filter(all, func(m: Message): Bool {
        m.time >= since
    });
    List.toArray(filteredMessages)
  };
};
