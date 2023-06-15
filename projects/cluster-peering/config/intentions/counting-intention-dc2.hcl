Kind = "service-intentions"
Name = "counting"
Sources = [
  {
    Name = "dashboard"
    Action = "allow"
    Peer = "cluster-01"
  }
]