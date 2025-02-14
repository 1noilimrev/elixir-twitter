defmodule TwitterWeb.TimelineLive do
	use TwitterWeb, :live_view
	alias Twitter.Timeline
	alias Twitter.Tweet

	def mount(_params, _session, socket) do
		tweets = Timeline.list_tweets()
		changeset = Timeline.change_tweet(%Tweet{})

		{:ok,
		 socket
		 |> assign(:tweets, tweets)
		 |> assign(:changeset, changeset)}
	end

	def handle_event("save-post", %{"content" => content}, socket) when content != "" do
		case Timeline.create_tweet(%{content: content, username: "User", likes_count: 0}) do
			{:ok, tweet} ->
				{:noreply,
				 socket
				 |> update(:tweets, fn tweets -> [tweet | tweets] end)
				 |> put_flash(:info, "Tweet posted successfully!")}

			{:error, %Ecto.Changeset{} = changeset} ->
				{:noreply, assign(socket, changeset: changeset)}
		end
	end

	def handle_event("save-post", _, socket) do
		{:noreply, put_flash(socket, :error, "Tweet cannot be empty")}
	end

	def render(assigns) do
		~H"""
		<div class="max-w-2xl mx-auto">
			<div class="mb-8 bg-white rounded-lg shadow p-6">
				<form phx-submit="save-post" class="space-y-4">
					<textarea
						name="content"
						placeholder="무슨 일이 일어나고 있나요?"
						class="w-full p-4 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
						rows="3"
					></textarea>
					<div class="flex justify-end">
						<button type="submit" class="px-6 py-2 bg-blue-500 text-white rounded-full hover:bg-blue-600 transition-colors">
							트윗하기
						</button>
					</div>
				</form>
			</div>

			<div id="tweets" phx-update="stream" class="space-y-4">
				<%= for tweet <- @tweets do %>
					<div class="bg-white rounded-lg shadow p-6">
						<div class="flex items-start space-x-3">
							<div class="flex-shrink-0">
								<div class="w-12 h-12 rounded-full bg-gray-200"></div>
							</div>
							<div class="flex-1">
								<div class="flex items-center space-x-2">
									<span class="font-bold"><%= tweet.username %></span>
									<span class="text-gray-500">·</span>
									<span class="text-gray-500"><%= format_time(tweet.inserted_at) %></span>
								</div>
								<p class="mt-2 text-gray-900"><%= tweet.content %></p>
								<div class="mt-3 flex items-center space-x-8 text-gray-500">
									<button class="flex items-center space-x-2 hover:text-blue-500">
										<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
											<path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd" />
										</svg>
										<span><%= tweet.likes_count %></span>
									</button>
								</div>
							</div>
						</div>
					</div>
				<% end %>
			</div>
		</div>
		"""
	end

	defp format_time(nil), do: ""
	defp format_time(timestamp) do
		Calendar.strftime(timestamp, "%Y-%m-%d %H:%M")
	end
end
