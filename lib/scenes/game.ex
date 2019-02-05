defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [text: 3]

  # Constants
  @graph Graph.build(font: :roboto, font_size: 36)
  @tile_size 32

  # Initialize the game scene
  def init(_arg, opts) do
    viewport = opts[:viewport]

    # The entire game state will be held here
    state = %{
      viewport: viewport,
      graph: @graph,
      score: 0
    }

    # Update the graph and push it to be rendered
    state.graph
    |> draw_score(state.score)
    |> push_graph()

    {:ok, state}
  end

  # Draw the score HUD
  defp draw_score(graph, score) do
    graph
    |> text("Score: #{score}", fill: :white, translate: {@tile_size, @tile_size})
  end
end
