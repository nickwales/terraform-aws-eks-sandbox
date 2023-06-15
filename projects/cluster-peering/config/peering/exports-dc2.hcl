Kind = "exported-services"
Name = "default"
Services = [
  {
    Name = "counting"
    Consumers = [
      {
        Peer = "cluster-01"
      }
    ]
  }
]