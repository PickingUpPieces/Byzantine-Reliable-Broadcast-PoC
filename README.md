# Byzantine Reliable Broadcast (BRB) PoC Implementation
This is a prototype/PoC implementation of the Byzantine Reliable Broadcast (BRB) as described in the paper [Asynchronous Byzantine Agreement Protocols](https://www.sciencedirect.com/science/article/pii/089054018790054X) by Gabriel Bracha.
This was done for the Summer School [DARE2023](https://soft.vub.ac.be/dare23/).
Some code was provided from organisers of the Summer School.

## Execution
The implementation is written in Elixir and can be compiled by running the following command in the root folder of the project: `mix compile`.
One it is compiled, start the application by running: `iex -S mix`. This will start an interactive shell with the application loaded.
To start a fixed number of nodes, run the following command in the interactive shell: `ChatServerBRB.start_all`.
To send a broadcast message, you have to specify the sending node and the message. Run the following command in the interactive shell: `ChatServerBRB.brb_broadcast(:elisa, :hi)`
