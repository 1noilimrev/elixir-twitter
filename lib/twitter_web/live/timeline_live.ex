defmodule TwitterWeb.TimelineLive do
	use TwitterWeb, :live_view
	alias Twitter.Timeline
	alias Twitter.Tweet

	@max_tweet_length 140

	def mount(_params, _session, socket) do
		tweets = Timeline.list_tweets()
		changeset = Timeline.change_tweet(%Tweet{})

		{:ok,
		 socket
		 |> assign(:tweets, tweets)
		 |> assign(:changeset, changeset)
		 |> assign(:char_count, 0)
		 |> assign(:content, "")
		 |> assign(:username, nil)}
	end

	def handle_event("validate-content", %{"content" => content}, socket) do
		char_count = String.length(content)

		{:noreply,
		 socket
		 |> assign(:char_count, char_count)
		 |> assign(:content, content)}
	end

	def handle_event("save-username", %{"username" => username}, socket) do
		{:noreply, assign(socket, :username, username)}
	end

	def handle_event("save-post", %{"content" => content}, socket)
		when content != "" and byte_size(content) <= @max_tweet_length and not is_nil(socket.assigns.username) do
		case Timeline.create_tweet(%{
			content: content,
			username: socket.assigns.username,
			likes_count: 0
		}) do
			{:ok, tweet} ->
				{:noreply,
				 socket
				 |> update(:tweets, fn tweets -> [tweet | tweets] end)
				 |> assign(:char_count, 0)
				 |> assign(:content, "")
				 |> put_flash(:info, "Tweet posted successfully!")}

			{:error, %Ecto.Changeset{} = changeset} ->
				{:noreply, assign(socket, changeset: changeset)}
		end
	end

	def handle_event("save-post", _, socket) do
		cond do
			is_nil(socket.assigns.username) ->
				{:noreply, put_flash(socket, :error, "Please enter a username first")}
			socket.assigns.char_count > @max_tweet_length ->
				{:noreply, put_flash(socket, :error, "Tweet is too long (maximum is 140 characters)")}
			true ->
				{:noreply, put_flash(socket, :error, "Tweet cannot be empty")}
		end
	end

	def render(assigns) do
		~H"""
		<div class="max-w-2xl mx-auto">
			<div class="mb-4 bg-white rounded-lg shadow p-6">
				<form phx-submit="save-username" class="mb-4">
					<div class="flex space-x-4">
						<input
							type="text"
							name="username"
							placeholder="Enter your username"
							value={@username}
							class="flex-1 p-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
						/>
						<button type="submit" class="px-4 py-2 bg-blue-500 text-white rounded-full hover:bg-blue-600 transition-colors">
							Set Username
						</button>
					</div>
				</form>
			</div>

			<div class="mb-8 bg-white rounded-lg shadow p-6">
				<form phx-submit="save-post" phx-change="validate-content" class="space-y-4">
					<div class="relative">
						<textarea
							name="content"
							placeholder="무슨 일이 일어나고 있나요?"
							class={"w-full p-4 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 #{get_textarea_color(@char_count)}"}
							rows="3"
							value={@content}
						></textarea>
						<div class={"absolute bottom-2 right-2 text-sm font-medium #{get_counter_color(@char_count)}"}>
							<%= @char_count %>/140
						</div>
					</div>
					<div class="flex justify-between items-center">
						<div class="text-sm">
							<%= if @username do %>
								Posting as: <span class="font-bold"><%= @username %></span>
							<% else %>
								Please set a username first
							<% end %>
						</div>
						<button
							type="submit"
							class="px-6 py-2 bg-blue-500 text-white rounded-full hover:bg-blue-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
							disabled={is_nil(@username) or @char_count > 140 or @char_count == 0}
						>
							트윗하기
						</button>
					</div>
				</form>
			</div>

			<div id="tweets" class="space-y-4">
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

	defp get_textarea_color(char_count) do
		cond do
			char_count == 0 -> "border-gray-300"
			char_count <= 100 -> "border-green-500"
			char_count <= 140 -> "border-yellow-500"
			true -> "border-red-500"
		end
	end

	defp get_counter_color(char_count) do
		cond do
			char_count == 0 -> "text-gray-500"
			char_count <= 100 -> "text-green-500"
			char_count <= 140 -> "text-yellow-500"
			true -> "text-red-500"
		end
	end
end
