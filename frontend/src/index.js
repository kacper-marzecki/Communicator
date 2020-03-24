import "./main.css";
import { Elm } from "./Main.elm";
const USER_TOKEN = "user_token";

var stompClient = null;
let app = Elm.Main.init({
  flags: {
    backendApi: process.env.BACKEND_API
  },
  node: document.getElementById("root")
});

const connectWs = accessToken => {
  if (accessToken) {
    var socket = new SockJS("http://localhost:8080/ws_endpoint");
    stompClient = Stomp.over(socket);
    console.log("connecting with token : " + accessToken);
    stompClient.connect({ token: accessToken }, function(frame) {
      console.log("Connected: " + frame);
      subscribeToSocket(stompClient);
      sendHydratingMessages(stompClient);
    });
  } else {
    console.log("no token");
  }
};

const sendHydratingMessages = stomp => {
  sendWsEvent("/get_channels", {});
  sendWsEvent("/get_friends", {});
};

const subscribeToSocket = stomp => {
  stomp.subscribe("/user/topic/channels", channel => {
    app.ports.gotChannel.send(JSON.parse(channel.body));
  });
  stomp.subscribe("/user/topic/friends", channel => {
    app.ports.gotFriend.send(JSON.parse(channel.body));
  });
  stomp.subscribe("/user/topic/notification", channel => {
    showSnackbar(channel.body);
  });
  stomp.subscribe("/user/topic/deleted_friends", channel => {
    app.ports.deletedFriend.send(channel.body);
  });

  stomp.subscribe("/user/topic/messages", channel => {
    app.ports.gotMessage.send(JSON.parse(channel.body));
  });
  stomp.subscribe("/user/topic/previous_messages", channel => {
    app.ports.gotPreviousMessage.send(JSON.parse(channel.body));
  });
};

const sendWsEvent = (topic, value) => {
  if (stompClient != null) {
    stompClient.send("/app" + topic, {}, JSON.stringify(value));
  } else {
    console.error("NULL STOMP CLIENT");
  }
};

const disconnectWs = () => {
  if (stompClient !== null) {
    stompClient.disconnect();
    stompClient = null;
  } else {
    console.error("NULL STOMP CLIENT");
  }
  console.log("Disconnected");
};

const saveToLocalStorage = (key, value) => {
  localStorage.setItem(key, JSON.stringify(value));
};

const readUserFromLocalStorage = () => {
  return JSON.parse(localStorage.getItem(USER_TOKEN));
};

const copyToClipboard = string => {
  const el = document.createElement("textarea");
  el.value = string;
  el.setAttribute("readonly", "");
  el.style.position = "absolute";
  el.style.left = "-9999px";
  document.body.appendChild(el);
  const selected =
    document.getSelection().rangeCount > 0
      ? document.getSelection().getRangeAt(0)
      : false;
  el.select();
  document.execCommand("copy");
  document.body.removeChild(el);
  if (selected) {
    document.getSelection().removeAllRanges();
    document.getSelection().addRange(selected);
  }
};

const showSnackbar = string => {
  app.ports.showSnackbarIn.send(string);
};

app.ports.copyToClipboard.subscribe(function(data) {
  copyToClipboard(data);
  showSnackbar("Copied to clipboard");
});

app.ports.openLink.subscribe(link => {
  window.open(link, "_blank");
});

app.ports.saveUser.subscribe(user => {
  saveToLocalStorage(USER_TOKEN, user);
  let accessToken = readUserFromLocalStorage();
  app.ports.getSavedUser.send(accessToken);
});

app.ports.connectWs.subscribe(() => {
  let accessToken = readUserFromLocalStorage();
  connectWs(accessToken.token);
});

app.ports.showSnackbarOut.subscribe(msg => {
  app.ports.showSnackbarIn.send(msg);
});

app.ports.getChannels.subscribe(() => {
  sendWsEvent("/get_channels", {});
});

app.ports.scrollMessagesToBottom.subscribe(() => {
  window.setTimeout(() => {
    var elem = document.getElementById("messagesView");
    elem.scrollTop = elem.scrollHeight;
  }, 100);
});

app.ports.scrollMessagesToTop.subscribe(() => {
  window.setTimeout(() => {
    var elem = document.getElementById("messagesView");
    elem.scrollTop = 0;
  }, 100);
});

app.ports.logoutJs.subscribe(() => {
  stompClient.disconnect();
  stompClient = null;
  localStorage.removeItem(USER_TOKEN);
});

app.ports.getSavedUser.send(readUserFromLocalStorage());
